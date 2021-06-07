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
    
    var dataProvider: HomeDataProvider?
    var alertData: GlobalAlertRow? {
        return dataProvider?.globalAlertsData
    }
    private var dataSource: [[String : String]] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setUpTableView()
        loadGlobalAlertsData()
    }
    
    private var loadGlobalAlertsInProgress = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    private func loadGlobalAlertsData() {
        if let forceUpdateAlertDetails = dataProvider?.forceUpdateAlertDetails, forceUpdateAlertDetails {
            loadGlobalAlertsInProgress = true
            dataProvider?.getGlobalAlertsIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
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
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "GlobalAlertDetailsCell", bundle: nil), forCellReuseIdentifier: "GlobalAlertDetailsCell")
        tableView.register(UINib(nibName: "GlobalAlertDetailsHeaderCell", bundle: nil), forCellReuseIdentifier: "GlobalAlertDetailsHeaderCell")
    }
    
    private func setUpDataSource() {
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
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension GlobalAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return dataSource.count
        }
        //return dataSource.count
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView = GlobalAlertDetailsHeader.instanceFromNib()
//        headerView.alertNumberLabel.text = alertData?.ticketNumber
//        headerView.alertTitleLabel.text = alertData?.alertTitle
//        headerView.setStatus(alertData?.status)
//        return headerView
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if loadGlobalAlertsInProgress {
                return createLoadingCell(withBottomSeparator: true)
            }
            if dataSource.count == 0 {
                return createErrorCell(with: "No data available")
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertDetailsHeaderCell", for: indexPath) as? GlobalAlertDetailsHeaderCell
            cell?.alertNumberLabel.text = alertData?.ticketNumber
            cell?.alertTitleLabel.text = alertData?.alertTitle
            cell?.setStatus(alertData?.status)
            return cell ?? UITableViewCell()
        }
        guard dataSource.count > indexPath.row, let key = dataSource[indexPath.row].keys.first else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertDetailsCell", for: indexPath) as? GlobalAlertDetailsCell
        cell?.titleLabel.text = key
        cell?.descriptionLabel.text = dataSource[indexPath.row][key]
//        let htmlBody = dataProvider?.formNewsBody(from: text)
//        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
//            htmlBody?.setFontFace(font: neededFont)
//        }
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
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.width * 0.8)
        var statusBarHeight: CGFloat = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 10 : statusBarHeight - 20
        return PanModalHeight.contentHeight(UIScreen.main.bounds.height - (coefficient + statusBarHeight))
    }
}
