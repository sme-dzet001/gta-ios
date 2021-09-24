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
        self.navigationController?.setNavigationBarHidden(false, animated: false)
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
//        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.alpha = 1
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
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
    }

    private func setUpTableView() {
        let additionalSeparator: CGFloat = UIDevice.current.hasNotch ? 8 : 34
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: (tableView.frame.width * 0.133) + additionalSeparator, right: 0)
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
        
        
        let metricsData = MetricsData(
            dailyData: [ChartData(legendTitle: "18/11/20", periodFullTitle: "18 November 2020", value: 85), ChartData(legendTitle: "17/11/20", periodFullTitle: "17 November 2020", value: 62), ChartData(legendTitle: "16/11/20", periodFullTitle: "16 November 2020", value: 105), ChartData(legendTitle: "15/11/20", periodFullTitle: "15 November 2020", value: 100), ChartData(legendTitle: "14/11/20", periodFullTitle: "14 November 2020", value: 70), ChartData(legendTitle: "13/11/20", periodFullTitle: "13 November 2020", value: 95), ChartData(legendTitle: "12/11/20", periodFullTitle: "12 November 2020", value: 100)],
            weeklyData: [ChartData(legendTitle: "18 Nov W/E", periodFullTitle: "18 Nov W/E", value: 690), ChartData(legendTitle: "11 Nov W/E", periodFullTitle: "11 Nov W/E", value: 705), ChartData(legendTitle: "4 Nov W/E", periodFullTitle: "4 Nov W/E", value: 740), ChartData(legendTitle: "28 Oct W/E", periodFullTitle: "28 Oct W/E", value: 520), ChartData(legendTitle: "21 Oct W/E", periodFullTitle: "21 Oct W/E", value: 730), ChartData(legendTitle: "14 Oct W/E", periodFullTitle: "14 Oct W/E", value: 720), ChartData(legendTitle: "7 Oct W/E", periodFullTitle: "7 Oct W/E", value: 430)],
            monthlyData: [ChartData(legendTitle: "11/2020", periodFullTitle: "November 2020", value: 5000), ChartData(legendTitle: "10/2020", periodFullTitle: "October 2020", value: 5450), ChartData(legendTitle: "9/2020", periodFullTitle: "September 2020", value: 5900), ChartData(legendTitle: "8/2020", periodFullTitle: "August 2020", value: 5300), ChartData(legendTitle: "7/2020", periodFullTitle: "July 2020", value: 4100), ChartData(legendTitle: "6/2020", periodFullTitle: "June 2020", value: 5100), ChartData(legendTitle: "5/2020", periodFullTitle: "May 2020", value: 2050)]
        )
        

        
        var firstSection = [AppInfo(app_name: "Report Outages, System Issues", app_title: "Report Issue", imageData: bellData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Reset Account Access & login Assistance", app_title: "Login Help", imageData: loginHelpData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Description, wiki and support information", app_title: "About", imageData: aboutData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Get the most from the app", app_title: "Tips & Tricks", imageData: tipsNtricksData?.pngData(), appStatus: .none, app_is_active: true), AppInfo(app_name: "Key Contacts and Member Profiles", app_title: "Contacts", imageData: contactsData?.pngData(), appStatus: .none, app_is_active: true)]
        
//        let secondSection = [AppInfo(app_name: "08/15/20 – 06:15 +5 GMT", app_title: "System restore", appImageData: AppsImageData(app_icon: "", imageData: nil, imageStatus: .loaded), appStatus: .none, app_is_active: true), AppInfo(app_name: "08/15/20 – 06:15 +5 GMT", app_title: "Scheduled maintenance", appImageData: AppsImageData(app_icon: "", imageData: nil, imageStatus: .loaded), appStatus: .none, app_is_active: true), AppInfo(app_name: "08/15/20 – 06:15 +5 GMT", app_title: "System restore", appImageData: AppsImageData(app_icon: "", imageData: nil, imageStatus: .loaded), appStatus: .none, app_is_active: true), AppInfo(app_name: "08/15/20 – 06:15 +5 GMT", app_title: "AWS outage reported", appImageData: AppsImageData(app_icon: "", imageData: nil, imageStatus: .loaded), appStatus: .none, app_is_active: true)]
//
        if productionAlertsSectionAvailable {
            firstSection.insert(AppInfo(app_name: "", app_title: "Production Alerts", imageData: alertIcon?.pngData(), appStatus: .none, app_is_active: true), at: 0)
        }
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: firstSection, metricsData: nil)/*, AppsDataSource(sectionName: "System Updates", description: nil, cellData: secondSection), AppsDataSource(sectionName: "Stats", description: nil, cellData: [], metricsData: metricsData)*/]
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
        //aboutScreen.appImageUrl = appImageUrl
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
        reportScreen.pickerDataSource = indexPath.row == 0 ? reportIssueTypes : loginIssueTypes
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
        if let metricsData = dataSource[section].metricsData {
            switch selectedMetricsPeriod {
            case .daily:
                return metricsData.dailyData.count
            case .weekly:
                return metricsData.weeklyData.count
            case .monthly:
                return metricsData.monthlyData.count
            }
        }
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
            //dataProvider?.formatDateString(dateString: appLastUpdateDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS")
            return statusHeader
        } else if let metricsData = dataSource[section].metricsData {
            let metricStatsHeader = MetricStatsHeader.instanceFromNib()
            metricStatsHeader.delegate = self
            metricStatsHeader.setUpHeaderData(selectedPeriod: selectedMetricsPeriod)
            metricStatsHeader.setChartData(selectedPeriod: selectedMetricsPeriod, data: metricsData)
            return metricStatsHeader
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
        } else if let _ = dataSource[section].metricsData {
            return 380
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
//        switch indexPath.section {
//        case 1:
//            return 80
//        default:
//            return UITableView.automaticDimension
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataArray = dataSource[indexPath.section].cellData
        if indexPath.section == 0, indexPath.row == 0, productionAlertsSectionAvailable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductionAlertCounterCell", for: indexPath) as? ProductionAlertCounterCell
            //let totalCount = alertsData?.data?.filter({$0?.isRead == false}).count ?? 0
            cell?.setAlert(alertCount: alertsCount == 0 ? nil : alertsCount, setTap: false)
            //cell?.updatesNumberLabel.text = totalCount == 0 ? nil : totalCount
            cell?.cellTitle.text = "Production Alerts"
            return cell ?? UITableViewCell()
        }
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.separator.isHidden = false//indexPath.row == dataArray.count - 1
            let isDisabled = indexPath.row < 4 && (appDetailsData?.appSupportEmail == nil || (appDetailsData?.appSupportEmail ?? "").isEmpty || appDetailsData == nil)
            cell.setUpCell(with: dataArray[indexPath.row], isNeedCornerRadius: indexPath.row == 0, isDisabled: isDisabled, error: indexPath.row == 3 ? nil : detailsDataResponseError)
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
        if let metricsData = dataSource[indexPath.section].metricsData, let cell = tableView.dequeueReusableCell(withIdentifier: "MetricStatsCell", for: indexPath) as? MetricStatsCell {
            var metricsDataSource = [ChartData]()
            switch selectedMetricsPeriod {
            case .daily:
                metricsDataSource = metricsData.dailyData
            case .weekly:
                metricsDataSource = metricsData.weeklyData
            case .monthly:
                metricsDataSource = metricsData.monthlyData
            }
            cell.setUpCell(with: metricsDataSource[indexPath.row], hideSeparator: indexPath.row == metricsDataSource.count - 1)
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
            showAboutScreen()
        } else if indexPath.row == commandBase + 1 {
            showTipsAndTricks()
        } else if indexPath.row == commandBase + 2 {
            showContacts()
        } else {
            showHelpReportScreen(for: indexPath)
        }
    }
    
}

extension ApplicationStatusViewController: MetricStatsHeaderDelegate {
    func periodWasChanged(_ header: MetricStatsHeader, to period: MetricsPeriod) {
        selectedMetricsPeriod = period
        let sectionIndexToReload = 2
        let indexPaths = tableView.visibleCells.compactMap { tableView.indexPath(for: $0) }.filter { $0.section == sectionIndexToReload
        }
        header.setChartData(selectedPeriod: period, data: dataSource[sectionIndexToReload].metricsData)
        tableView.reloadRows(at: indexPaths, with: .none)
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
