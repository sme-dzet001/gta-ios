//
//  Office365ViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.03.2021.
//

import UIKit

class Office365ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var errorLabel: UILabel!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    
    var dataProvider: CollaborationDataProvider?
    var appName: String = ""
    var alertsData: ProductionAlertsResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        setAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        getAppSuiteDetails()
        //dataProvider?.imageLoadingDelegate = self
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Office 365 Applications"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.title = appName
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "Office365ScreenTableView"
        self.navigationItem.titleView?.accessibilityIdentifier = "Office365ScreenTitleView"
        self.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "Office365ScreenBackButton"
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if dataProvider?.collaborationAppDetailsRows != nil {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func getAppSuiteDetails() {
        if dataProvider?.collaborationAppDetailsRows == nil {
            startAnimation()
        }
        dataProvider?.getAppDetails(appSuite: appName) {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                if error != nil || errorCode != 200 {
                    self?.errorLabel.isHidden = self?.dataProvider?.collaborationAppDetailsRows != nil
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
                if dataWasChanged { self?.tableView.reloadData() }
                self?.stopAnimation()
            }
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "Office365AppCell", bundle: nil), forCellReuseIdentifier: "Office365AppCell")
        tableView.register(UINib(nibName: "ProductionAlertCounterCell", bundle: nil), forCellReuseIdentifier: "ProductionAlertCounterCell")
    }
    
    private func showAppDetailsScreen(with details: CollaborationAppDetailsRow) {
        let aboutScreen = AboutViewController()
        aboutScreen.isCollaborationDetails = true
        aboutScreen.collaborationDetails = details
        aboutScreen.appTitle = details.fullTitle
        aboutScreen.appImageUrl = details.fullImageUrl ?? ""
        navigationController?.pushViewController(aboutScreen, animated: true)
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension Office365ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return alertsData == nil ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && alertsData != nil {
            return 1
        }
        if let count = dataProvider?.collaborationAppDetailsRows?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let _ = alertsData {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductionAlertCounterCell", for: indexPath) as? ProductionAlertCounterCell
            cell?.updatesNumberLabel.text = "\(alertsData?.data?.count ?? 0)"
            return cell ?? UITableViewCell()
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Office365AppCell", for: indexPath) as? Office365AppCell {
            guard let cellData = dataProvider?.collaborationAppDetailsRows else { return cell }
            cell.setUpCell(with: cellData[indexPath.row], isAppsScreen: true)
            let imageURL = dataProvider?.formImageURL(from: cellData[indexPath.row].imageUrl)
            let url = URL(string: imageURL ?? "")
            cell.appTitleLabel.accessibilityIdentifier = "Office365ScreenTitleLabel"
            cell.descriptionLabel.accessibilityIdentifier = "Office365ScreenDescriptionLabel"
            cell.iconImageView.kf.indicatorType = .activity
            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                switch result {
                case .success(let resData):
                    cell.iconImageView.image = resData.image
                case .failure(let error):
                    if !error.isNotCurrentTask {
                        cell.showFirstChar()
                    }
                }
            })
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: (tableView.frame.width * 0.133) + 24 ))
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let footerHeight = (tableView.frame.width * 0.133) + 24
        return footerHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, alertsData != nil {
            let alertsScreen = ProductionAlertsViewController()
            //alertsScreen.dataSource = alertsData
            self.navigationController?.pushViewController(alertsScreen, animated: true)
            return
        }
        guard let detailsRows = dataProvider?.collaborationAppDetailsRows, indexPath.row < detailsRows.count else { return }
        showAppDetailsScreen(with: detailsRows[indexPath.row])
    }
}
