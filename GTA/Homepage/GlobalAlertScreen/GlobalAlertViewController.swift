//
//  GlobalAlertViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 14.05.2021.
//

import UIKit
import PanModal

class GlobalAlertViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var isProdAlert: Bool = false
    var productionAlertId: String? = nil
    var dataProvider: HomeDataProvider?
    var alertData: GlobalAlertRow? {
        return dataProvider?.globalAlertsData
    }
    var prodAlertData: ProductionAlertsRow? {
        if productionAlertId != nil {
            return dataProvider?.activeProductionGlobalAlert
        }
        return dataProvider?.productionGlobalAlertsData
    }
    private var dataSource: [[String : String]] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    private let errorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var shortHeight: CGFloat {
        guard !UIDevice.current.iPhone5_se else { return view.frame.height }
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return coefficient - (view.window?.safeAreaInsets.bottom ?? 0)
    }
    
    private var loadGlobalAlertsInProgress = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setUpTableView()
        if isProdAlert {
            loadProductionGlobalAlertsData()
        } else {
            loadGlobalAlertsData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataProvider?.forceUpdateAlertDetails = false
    }
    
    private func loadGlobalAlertsData() {
        if let forceUpdateAlertDetails = dataProvider?.forceUpdateAlertDetails, forceUpdateAlertDetails {
            loadGlobalAlertsInProgress = true
            dataProvider?.getGlobalAlertsIgnoringCache(completion: {[weak self] _, dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.dataProvider?.forceUpdateAlertDetails = false
                    if let alert = self?.dataProvider?.globalAlertsData, !alert.isExpired {
                        self?.setUpDataSource()
                    }
                    self?.loadGlobalAlertsInProgress = false
                }
            })
        } else {
            setUpDataSource()
        }
    }
    
    private func loadProductionGlobalAlertsData() {
        if let forceUpdateAlertDetails = dataProvider?.forceUpdateAlertDetails, forceUpdateAlertDetails {
            loadGlobalAlertsInProgress = true
            dataProvider?.getGlobalProductionIgnoringCache(alertID: productionAlertId, completion: {[weak self] dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.dataProvider?.forceUpdateAlertDetails = false
                    if let alert = self?.dataProvider?.productionGlobalAlertsData, !alert.isExpired {
                        self?.setUpDataSource()
                    } else {
                        self?.errorLabel.text = "Global Production Alert has been closed"
                    }
                    self?.loadGlobalAlertsInProgress = false
                }
            })
        } else {
            setUpDataSource()
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "GlobalAlertDetailsCell", bundle: nil), forCellReuseIdentifier: "GlobalAlertDetailsCell")
        tableView.register(UINib(nibName: "GlobalAlertDetailsHeaderCell", bundle: nil), forCellReuseIdentifier: "GlobalAlertDetailsHeaderCell")
    }
    
    private func setUpDataSource() {
        dataSource = []
        if isProdAlert {
            setUpProductionAlertsDataSource()
        } else {
            setUpGlobalAlertsDataSource()
        }
    }
    
    private func setUpProductionAlertsDataSource() {
        if let start = prodAlertData?.startDateString {
            dataSource.append(["Notification Date" : start.getFormattedDateStringForMyTickets()])
        }
        if let duration = prodAlertData?.duration, prodAlertData?.status != .closed {
            dataSource.append(["Maintenance Duration" : duration])
        }
        if let end = prodAlertData?.closeDateString, prodAlertData?.status == .closed {
            dataSource.append(["Close Date" : end.getFormattedDateStringForMyTickets()])
        }
        if let summary = prodAlertData?.description {
            dataSource.append(["Summary" : summary])
        }
        if let jiraTicket = prodAlertData?.sourceJiraIssue {
            dataSource.append(["Original Source Jira Issue" : jiraTicket])
        }
        if let closeComment = prodAlertData?.lastComment, prodAlertData?.status == .closed {
            dataSource.append(["Close Comment" : closeComment])
        }
    }
    
    private func setUpGlobalAlertsDataSource() {
        if let start = alertData?.notificationDate {
            dataSource.append(["Notification Date" : start])
        }
        if let duration = alertData?.estimatedDuration, alertData?.status != .closed {
            dataSource.append(["Estimated Duration" : duration])
        }
        if let end = alertData?.endDate, alertData?.status == .closed {
            dataSource.append(["Close Date" : end])
        }
        if let summary = alertData?.description {
            dataSource.append(["Summary" : summary])
        }
        if let jiraTicket = alertData?.jiraIssue {
            dataSource.append(["Original Source Jira Issue" : jiraTicket])
        }
        if let closeComment = alertData?.closeComment, alertData?.status == .closed {
            dataSource.append(["Close Comment" : closeComment])
        }
    }
    
    private func setActivityIndicator(_ needToShow: Bool) {
        if needToShow {
            view.addSubview(activityIndicator)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.topAnchor, constant: shortHeight / 2)
            ])
            activityIndicator.startAnimating()
            tableView.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            tableView.isHidden = false
        }
    }
    
    private func setErrorLabel(_ needToShow: Bool) {
        if needToShow {
            view.addSubview(errorLabel)
            errorLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                errorLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: shortHeight / 2),
                errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ])
            errorLabel.numberOfLines = 0
            errorLabel.font = UIFont(name: "SFProText-Regular", size: 16)!
            errorLabel.textAlignment = .center
            errorLabel.textColor = .black
            errorLabel.adjustsFontSizeToFitWidth = true
            errorLabel.minimumScaleFactor = 0.7
            errorLabel.text = "No data available"
        } else {
            errorLabel.removeFromSuperview()
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension GlobalAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadGlobalAlertsInProgress {
            setActivityIndicator(true)
            return 0
        }
        if dataSource.count == 0 {
            setErrorLabel(true)
            return 0
        }
        setActivityIndicator(false)
        setErrorLabel(false)
        switch section {
        case 0:
            return 1
        default:
            return dataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertDetailsHeaderCell", for: indexPath) as? GlobalAlertDetailsHeaderCell
            cell?.alertNumberLabel.text = !isProdAlert ? alertData?.ticketNumber : prodAlertData?.ticketNumber
            cell?.alertTitleLabel.text = !isProdAlert ? alertData?.alertTitle : prodAlertData?.issueReason
            cell?.setStatus(!isProdAlert ? alertData?.status : prodAlertData?.status)
            return cell ?? UITableViewCell()
        }
        guard dataSource.count > indexPath.row, let key = dataSource[indexPath.row].keys.first else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertDetailsCell", for: indexPath) as? GlobalAlertDetailsCell
        cell?.titleLabel.text = key
        cell?.descriptionLabel.text = dataSource[indexPath.row][key]
        return cell ?? UITableViewCell()
    }
    
}

extension GlobalAlertViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return tableView
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var panModalBackgroundColor: UIColor {
        return .clear
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var shortFormHeight: PanModalHeight {
        return PanModalHeight.contentHeight(shortHeight)
    }
    
    var allowsExtendedPanScrolling: Bool {
        return true
    }
}
