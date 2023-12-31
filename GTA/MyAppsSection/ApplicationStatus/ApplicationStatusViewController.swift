//
//  ApplicationStatusViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 11.11.2020.
//

import UIKit
import PanModal
import MessageUI

enum MetricsPeriod {
    case daily
    case weekly
    case monthly
}

class ApplicationStatusViewController: UIViewController, SendEmailDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSeparator: UIView!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var lastUpdateDate: Date?
    var dataProvider: MyAppsDataProvider?
    var dataSource: [AppsDataSource] = []
    var appDetailsData: AppDetailsData? {
        didSet {
            detailsDataDelegate?.detailsDataUpdated(detailsData: appDetailsData, error: detailsDataResponseError)
        }
    }
    var appName: String = ""
    var appTitle: String?
    var appImageUrl: String = ""
    var appLastUpdateDate: String?
    var systemStatus: SystemStatus = .none
    var selectedMetricsPeriod: MetricsPeriod = .weekly
    var detailsDataResponseError: Error?
    weak var detailsDataDelegate: DetailsDataDelegate?
    var alertsData: [ProductionAlertsRow]?
    private var activeAlertsCount: Int {
        return dataProvider?.alertsData[appName]?.filter({$0.isExpired == false}).count ?? 0
    }
    private var alertsCount: Int {
        return dataProvider?.alertsData[appName]?.filter({$0.isRead == false && $0.isExpired == false}).count ?? 0
    }
    private var productionAlertsSectionAvailable: Bool {
        return alertsData != nil && activeAlertsCount > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "AppsStatusTableView"
        setHardCodeData()
        setUpTableView()
        setUpNavigationItem()
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        getProductionAlerts()
        getMyApps()
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            getAppDetailsData()
        }
        if let alertsData = dataProvider?.alertsData[appName] {
            self.alertsData = alertsData
        }
        tableView.reloadData()
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: 0xF9F9FB)
        setUpNavigationBarForStatusScreen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataProvider?.activeProductionAlertId != nil {
            showProductionAlertScreen()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setUpUIElementsForNewVersion()
    }
    
    private func getMyApps() {
        dataProvider?.getMyAppsStatus {[weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                if self?.tableView.dataHasChanged == true {
                    self?.tableView.reloadData()
                } else {
                    UIView.performWithoutAnimation {
                        self?.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
                    }
                }
            }
        }
    }
    
    private func getAppDetailsData() {
        startAnimation()
        dataProvider?.getAppDetailsData(for: appName) { [weak self] (detailsData, errorCode, error, fromCache) in
            self?.detailsDataResponseError = error
            if error == nil, errorCode == 200 {
                self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                self?.appDetailsData = detailsData
            }
            self?.stopAnimation()
        }
    }
    
    @objc private func getProductionAlerts() {
        dataProvider?.getProductionAlerts {[weak self] dataWasChanged, errorCode, error, count in
            DispatchQueue.main.async {
                if error == nil {
                    if let alertsData = self?.dataProvider?.alertsData[self?.appName ?? ""] {
                        self?.alertsData = alertsData
                    }
                    self?.setHardCodeData()
                    if self?.tableView.dataHasChanged == true {
                        self?.tableView.reloadData()
                    } else {
                        UIView.performWithoutAnimation {
                            self?.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
                        }
                    }
                }
            }
        }
    }
    
    private func startAnimation() {
        guard appDetailsData == nil else { return }
        self.tableView.alpha = 0
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.tableView.alpha = 1
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = appName
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.titleView?.accessibilityIdentifier = "AppsStatusTitleLabel"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
        self.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppsStatusBackButton"
        if #available(iOS 15.0, *) {
            headerSeparator.isHidden = false
        }
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.register(UINib(nibName: "SystemUpdatesCell", bundle: nil), forCellReuseIdentifier: "SystemUpdatesCell")
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "ProductionAlertCounterCell", bundle: nil), forCellReuseIdentifier: "ProductionAlertCounterCell")
        tableView.register(UINib(nibName: "MetricStatsCell", bundle: nil), forCellReuseIdentifier: "MetricStatsCell")
        /* TODO: Need to find a better solution
         * Adding view for top bounce
         */
        let bounceView = UIView(frame: self.tableView.bounds)
        bounceView.frame.origin.y = -self.tableView.bounds.height
        bounceView.backgroundColor = UIColor(hex: 0xF7F7FA)
        self.tableView.addSubview(bounceView)
    }
    
    private func setHardCodeData() {
        let bellData = UIImage(named: "report_icon")
        let loginHelpData = UIImage(named: "login_help")
        let aboutData = UIImage(named: "info_icon")
        let contactsData = UIImage(named: "contacts_icon")
        let tipsNtricksData = UIImage(named: "tips_n_tricks_icon")
        let alertIcon = UIImage(named: "notification")
        var firstSection = [AppInfo(app_name: "Report Outages, System Issues", app_title: "Report Issue", imageData: bellData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Reset Account Access & login Assistance", app_title: "Login Help", imageData: loginHelpData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Description, wiki and support information", app_title: "About", imageData: aboutData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Get the most from the app", app_title: "Tips & Tricks", imageData: tipsNtricksData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Key Contacts and Member Profiles", app_title: "Contacts", imageData: contactsData?.pngData(), appStatus: .none, app_is_active: true)]
        if productionAlertsSectionAvailable {
            firstSection.insert(AppInfo(app_name: "", app_title: "Production Alerts", imageData: alertIcon?.pngData(), appStatus: .none, app_is_active: true), at: 0)
        }
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: firstSection)]
    }

    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func sendEmail(withTitle subject: String, withText body: String, to recipient: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setSubject(subject)
            mailVC.setToRecipients([recipient])
            mailVC.setMessageBody(body, isHTML: false)
            
            present(mailVC, animated: true)
        } else {
            displayError(errorMessage: "Configure your mail in iOS mail app to use this feature", title: nil)
        }
    }
    
    private func showProductionAlertScreen() {
        let alertsScreen = ProductionAlertsViewController()
        alertsScreen.dataProvider = dataProvider
        alertsScreen.appName = appName
        self.navigationController?.pushViewController(alertsScreen, animated: true)
    }
    
    private func showAboutScreen() {
        let aboutScreen = AboutViewController()
        aboutScreen.details = appDetailsData
        aboutScreen.detailsDataResponseError = detailsDataResponseError
        self.detailsDataDelegate = aboutScreen
        aboutScreen.appTitle = appTitle
        navigationController?.pushViewController(aboutScreen, animated: true)
    }
    
    private func showTipsAndTricks() {
        if let _ = appDetailsData, appDetailsData!.isNeedToUsePDF {
            let appTipsAndTricksVC = AppTipsAndTricksViewController()
            appTipsAndTricksVC.appName = appName
            appTipsAndTricksVC.pdfUrlString = appDetailsData?.tipsAndTricksPDF
            navigationController?.pushViewController(appTipsAndTricksVC, animated: true)
        } else {
            let appTipsAndTricksVC = QuickHelpViewController()
            appTipsAndTricksVC.appName = appName
            appTipsAndTricksVC.screenType = .appTipsAndTricks
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            appTipsAndTricksVC.appsDataProvider = dataProvider
            navigationController?.pushViewController(appTipsAndTricksVC, animated: true)
        }
    }
    
    private func showContacts() {
        let contactsScreen = AppContactsViewController()
        contactsScreen.dataProvider = dataProvider
        contactsScreen.appName = appName
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(contactsScreen, animated: true)
    }
    
    private func showHelpReportScreen(for indexPath: IndexPath) {
        if appDetailsData?.appSupportEmail == nil {
            return
        }
        let reportScreen = HelpReportScreenViewController()
        reportScreen.delegate = self
        reportScreen.screenTitle = dataSource[indexPath.section].cellData[indexPath.row].app_title
        reportScreen.appSupportEmail = appDetailsData?.appSupportEmail
        reportScreen.appName = appName
        let reportIssueTypes = ["Navigation issues", "Slow app work", "No connection", "Missing data", "App crash", "App freeze", "Other"]
        let loginIssueTypes = ["Invalid credentials error", "Forgot password", "2FA issue", "Other"]
        reportScreen.pickerDataSource = indexPath.row == (productionAlertsSectionAvailable ? 1 : 0) ? reportIssueTypes : loginIssueTypes
        presentPanModal(reportScreen)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
    }
    
}

extension ApplicationStatusViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let statusHeader = SystemStatusHeader.instanceFromNib()
            statusHeader.systemStatus = systemStatus
            statusHeader.dateLabel.text =  appLastUpdateDate?.getFormattedDateStringForMyTickets()
            statusHeader.systemStatusHeader.accessibilityIdentifier = "AppsStatusLabel"
            statusHeader.dateLabel.accessibilityIdentifier = "AppsStatusDateLabel"
            statusHeader.appStatusDescription.accessibilityIdentifier = "AppsStatusDescription"
            return statusHeader
        }
        let header = AppsTableViewHeader.instanceFromNib()
        header.descriptionLabel.text = dataSource[section].description
        header.headerTitleLabel.text = dataSource[section].sectionName
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if UIDevice.current.iPhone5_se {
                return self.view.frame.height / 2.5
            }
            return self.view.frame.height / 3
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataArray = dataSource[indexPath.section].cellData
        if indexPath.section == 0, indexPath.row == 0, productionAlertsSectionAvailable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductionAlertCounterCell", for: indexPath) as? ProductionAlertCounterCell
            cell?.setAlert(alertCount: alertsCount == 0 ? nil : alertsCount, setTap: false)
            cell?.cellTitle.text = "Production Alerts"
            return cell ?? UITableViewCell()
        }
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.separator.isHidden = false
            var isDisabled = false
            if indexPath.row < (productionAlertsSectionAvailable ? 3 : 2) && (appDetailsData?.appSupportEmail == nil || (appDetailsData?.appSupportEmail ?? "").isEmpty || appDetailsData == nil) {
                isDisabled = true
            } else if indexPath.row == (productionAlertsSectionAvailable ? 3 : 2), (appDetailsData?.appSupportPolicy == nil && appDetailsData?.appDescription == nil && appDetailsData?.appWikiUrl == nil && appDetailsData?.appJiraSupportUrl == nil) {
                isDisabled = true
            }
            cell.setUpCell(with: dataArray[indexPath.row], isNeedCornerRadius: indexPath.row == 0, isDisabled: isDisabled, index: indexPath.row, alerts: productionAlertsSectionAvailable, error: indexPath.row == 3 ? nil : detailsDataResponseError)
            cell.iconImageView.accessibilityIdentifier = "AppsStatusDescription"
            cell.descriptionLabel.accessibilityIdentifier = "AppsStatusSubtitleLabel"
            cell.mainLabel.accessibilityIdentifier = "AppsStatusTitleLabel"
            cell.arrowIcon.accessibilityIdentifier = "AppsStatusArrowImage"
            let values = appDetailsData?.values.compactMap({$0}) ?? []
            if let error = detailsDataResponseError as? ResponseError, error == .noDataAvailable, values.isEmpty {
                cell.setMainLabelAtCenter()
            }
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SystemUpdatesCell", for: indexPath) as? SystemUpdatesCell {
            cell.setUpCell(with: dataArray[indexPath.row], hideSeparator: indexPath.row == dataArray.count - 1)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        if indexPath.row == 0 && productionAlertsSectionAvailable {
            showProductionAlertScreen()
            return
        }
        let commandBase = productionAlertsSectionAvailable ? 3 : 2
        if indexPath.row == commandBase, (appDetailsData != nil) {
            if appDetailsData?.appSupportPolicy != nil || appDetailsData?.appDescription != nil || appDetailsData?.appWikiUrl != nil || appDetailsData?.appJiraSupportUrl != nil {
                showAboutScreen()
            }
        } else if indexPath.row == commandBase + 1 {
            showTipsAndTricks()
        } else if indexPath.row == commandBase + 2 {
            showContacts()
        } else {
            showHelpReportScreen(for: indexPath)
        }
    }
    
}

extension ApplicationStatusViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

protocol SendEmailDelegate: AnyObject {
    func sendEmail(withTitle subject: String, withText body: String, to recipient: String)
}

protocol DetailsDataDelegate: AnyObject {
    func detailsDataUpdated(detailsData: AppDetailsData?, error: Error?)
}
