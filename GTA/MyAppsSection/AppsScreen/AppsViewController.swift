//
//  AppsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit
import Kingfisher

class AppsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
   // var dataSource: [AppsDataSource] = []
    
    private var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    private var myAppsLastUpdateDate: Date?
    private var allAppsLastUpdateDate: Date?
    private var allAppsLoadingError: Error?
    private var myAppsLoadingError: Error?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productionAlertNotificationReceived), name: Notification.Name(NotificationsNames.productionAlertNotificationReceived), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationReceived), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        //self.dataProvider.appImageDelegate = self
        setUpNavigationItem()
        setAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProductionAlerts()
        addErrorLabel(errorLabel)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
        startAnimation()
        if allAppsLastUpdateDate == nil || Date() >= allAppsLastUpdateDate ?? Date() {
            self.getAllApps()
        }
        if myAppsLastUpdateDate == nil || Date() >= myAppsLastUpdateDate ?? Date() {
            self.getMyApps()
        }
        activateStatusRefresh()
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataProvider.invalidateStatusRefresh()
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "My Apps"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
    }
    
    private func activateStatusRefresh() {
        dataProvider.activateStatusRefresh {[weak self] (isNeedToRefresh) in
            guard isNeedToRefresh else { return }
            self?.getAllApps()
        }
    }
    
    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "AppsScreenTableView"
        self.navigationItem.titleView?.accessibilityIdentifier = "AppsScreenTitleView"
    }
    
    private func getMyApps() {
        myAppsLoadingError = nil
        dataProvider.getMyAppsStatus {[weak self] (errorCode, error, isFromCache) in
            self?.myAppsLoadingError = isFromCache ? nil : error
            DispatchQueue.main.async {
                self?.checkForPendingProductionAlert()
                if error == nil, errorCode == 200, let isEmpty = self?.dataProvider.appsData.isEmpty {
                    if !isFromCache {
                        self?.myAppsLastUpdateDate = Date().addingTimeInterval(15)
                    }
                    if !isEmpty {
                        self?.stopAnimation()
                    }
                } else if !isFromCache, let isEmpty = self?.dataProvider.appsData.isEmpty, !isEmpty {
                    self?.stopAnimation()
                } else if !isFromCache, let isEmpty = self?.dataProvider.appsData.isEmpty, isEmpty, self?.allAppsLoadingError != nil {
                    self?.stopAnimation()
                }
            }
        }
    }
    
    private func getAllApps() {
        allAppsLoadingError = nil
        dataProvider.getAllApps {[weak self] (errorCode, error, isFromCache) in
            self?.allAppsLoadingError = isFromCache ? nil : error
            DispatchQueue.main.async {
                self?.checkForPendingProductionAlert()
                if error == nil, errorCode == 200, let appsData = self?.dataProvider.appsData.first {
                    self?.errorLabel.isHidden = true
                    if !isFromCache {
                        self?.allAppsLastUpdateDate = Date().addingTimeInterval(60)
                    }
                    if !appsData.cellData.isEmpty || self?.myAppsLoadingError != nil {
                        self?.stopAnimation()
                    }
                    //let appInfo = self?.dataProvider.appsData.map({$0.cellData}).reduce([], {$0 + $1})
                    //self?.dataProvider.getImageData(for: appInfo ?? [])
                } else if !isFromCache {
                    self?.stopAnimation()
                }
            }
        }
    }
    
    @objc private func getProductionAlerts() {
        dataProvider.getProductionAlerts {[weak self] dataWasChanged, errorCode, error, count  in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.checkForPendingProductionAlert()
                if error == nil {
                    if dataWasChanged && self.isViewLoaded {
                        self.tableView.reloadData()
                    }
                    self.tabBarController?.addProductionAlertsItemBadge(atIndex: 2, value: count > 0 ? "\(count)" : nil)
                    guard let mainVC = self.tabBarController?.navigationController?.viewControllers.first(where: { $0 is MainViewController}) as? MainViewController else {return}
                    mainVC.menuViewController.productionAlertBadges = count
                }
            }
        }
    }
    
    private func checkForPendingProductionAlert() {
        if let productionAlertInfo = UserDefaults.standard.object(forKey: "productionAlertNotificationReceived") as? [String : Any] {
            dataProvider.forceUpdateProductionAlerts = true
            navigateToAppDetails(withProductionAlertInfo: productionAlertInfo)
        }
        UserDefaults.standard.removeObject(forKey: "productionAlertNotificationReceived")
    }
    
    private func startAnimation() {
        guard dataProvider.appsData.isEmpty else { return }
        self.errorLabel.isHidden = true
        self.tableView.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        guard dataProvider.myAppsStatusData != nil || myAppsLoadingError != nil else { return }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.errorLabel.isHidden = !(self.dataProvider.appsData.isEmpty && self.allAppsLoadingError != nil)
            self.errorLabel.text = (self.allAppsLoadingError as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
            self.tableView.alpha = !self.dataProvider.appsData.isEmpty ? 1 : 0
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "ApplicationCell", bundle: nil), forCellReuseIdentifier: "ApplicationCell")
    }
    
    private func showProductionAlertScreen(id: String?, appName: String) {
        guard let id = id else { return }
        let alertsScreen = ProductionAlertsViewController()
        alertsScreen.appName = appName
        alertsScreen.selectedId = id
        alertsScreen.dataProvider = dataProvider
        self.navigationController?.pushViewController(alertsScreen, animated: true)
    }
    
    @objc func productionAlertNotificationReceived(notification: NSNotification) {
        guard let productionAlertInfo = notification.userInfo as? [String : Any] else { return }
        dataProvider.forceUpdateProductionAlerts = true
        navigateToAppDetails(withProductionAlertInfo: productionAlertInfo)
    }
    
    private func navigateToAppDetails(withProductionAlertInfo alertData: [String : Any]) {
        guard let appName = alertData["app_name"] as? String else { return }
        //guard let targetAppData = dataProvider.myAppsSection?.cellData.first(where: { $0.app_name == appName }) else { return }
        guard let productionAlertId = alertData["production_alert_id"] as? String else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        UIApplication.shared.applicationIconBadgeNumber = 0
        //dataProvider.activeProductionAlertId = productionAlertId
        //dataProvider.activeProductionAlertAppName = appName
        appDelegate.dismissPanModalIfPresented { [weak self] in
            guard let self = self else { return }
            guard let embeddedController = self.navigationController else { return }
            guard let applicationsTabIdx = self.tabBarController?.viewControllers?.firstIndex(of: embeddedController) else { return }
            self.dataProvider.activeProductionAlertId = productionAlertId
            self.dataProvider.activeProductionAlertAppName = appName
            self.tabBarController?.selectedIndex = applicationsTabIdx
            embeddedController.popToRootViewController(animated: false)
            NotificationCenter.default.post(name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
            //show details for notification target app
            let appVC = ApplicationStatusViewController()
            appVC.appName = appName
            appVC.dataProvider = self.dataProvider
            if let targetAppData = self.dataProvider.myAppsSection?.cellData.first(where: { $0.app_name == appName }) {
                appVC.appTitle = targetAppData.app_title
                appVC.appImageUrl = targetAppData.appImage ?? ""
                appVC.appLastUpdateDate = targetAppData.lastUpdateDate
                appVC.systemStatus = targetAppData.appStatus
            }
            self.navigationController?.pushViewController(appVC, animated: true)
        }
    }
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = allAppsLoadingError, dataProvider.appsData.isEmpty {
            return 1
        }
        return dataProvider.appsData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = allAppsLoadingError, dataProvider.appsData.isEmpty {
            return 1
        }
        if dataProvider.appsData[section].sectionName == "My Apps" {
            let myAppsDataIsEmpty = dataProvider.appsData[section].cellData.isEmpty
            if let _ = myAppsLoadingError, myAppsDataIsEmpty {
                return 1
            }
            return dataProvider.appsData[section].cellData.count
        }
        return dataProvider.appsData[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if allAppsLoadingError != nil && dataProvider.appsData.isEmpty {
            return tableView.frame.height
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !dataProvider.appsData.isEmpty {
            let header = AppsTableViewHeader.instanceFromNib()
            header.descriptionLabel.text = dataProvider.appsData[section].description
            header.headerTitleLabel.text = dataProvider.appsData[section].sectionName
            header.headerTitleLabel.accessibilityIdentifier = "AppsScreenHeaderTitleLabel"
            header.descriptionLabel.accessibilityIdentifier = "AppsScreenHeaderDescriptionLabel"
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let error = allAppsLoadingError as? ResponseError, dataProvider.appsData.isEmpty {
            return createErrorCell(with: error.localizedDescription)
        }
        if indexPath.section == 0, let error = myAppsLoadingError as? ResponseError, let isEmpty = dataProvider.myAppsStatusData?.data?.isEmpty, isEmpty {
            return createErrorCell(with: error.localizedDescription)
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as? ApplicationCell {
            if indexPath.section < dataProvider.appsData.count, indexPath.row < dataProvider.appsData[indexPath.section].cellData.count {
                let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
                cell.setUpCell(with: cellData)
                cell.appIcon.accessibilityIdentifier = "AppsScreenCellIcon"
                cell.appStatus.accessibilityIdentifier = "AppsScreenAppStatus"
                cell.appName.accessibilityIdentifier = "AppsScreenAppNameTitleLabel"
                let url = URL(string: dataProvider.appsData[indexPath.section].cellData[indexPath.row].appImage ?? "")
                if let urlString = url?.absoluteString, !urlString.isEmptyOrWhitespace() {
                cell.appIcon.kf.indicatorType = .activity
                cell.appIcon.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                    //cell.stopAnimation()
                    switch result {
                    case .success(let resData):
                        cell.appIcon.image = resData.image
                    case .failure(let error):
                        if !error.isNotCurrentTask {
                            cell.showFirstChar()
                        }
                    }
                })
                } else {
                    cell.showFirstChar()
                }
                if indexPath.section == 0, let alerts = dataProvider.alertsData[cellData.app_name ?? ""]?.filter({$0.isRead == false}) {
                    cell.popoverShowDelegate = self
                    cell.showAlertScreenDelegate = self
                    cell.setAlert(alertCount: alerts.count)
                }
                cell.separator.isHidden = indexPath.row != dataProvider.appsData[indexPath.section].cellData.count - 1
            } else {
                print("!!!error my apps cell no data!!!!")
                return createErrorCell(with: "No data available")
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if allAppsLoadingError != nil && dataProvider.appsData.isEmpty {
            return 0
        }
        /*guard section != 0 else { return 0 }
        if section == 2 {
            return 80
        }
        return 60*/
        if section == 1 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: (tableView.frame.width * 0.133) + 24 ))
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == tableView.numberOfSections - 1 else { return 0 }
        
        let footerHeight = (tableView.frame.width * 0.133) + 24
        return footerHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard navigationController?.topViewController == self else { return }
        guard indexPath.section < dataProvider.appsData.count else { return }
        guard !dataProvider.appsData[indexPath.section].cellData.isEmpty else { return }
        let appVC = ApplicationStatusViewController()
        let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
        appVC.appName = cellData.app_name ?? ""
        appVC.appTitle = cellData.app_title
        appVC.appImageUrl = cellData.appImage ?? ""
        appVC.appLastUpdateDate = cellData.lastUpdateDate
        appVC.systemStatus = cellData.appStatus
        appVC.dataProvider = dataProvider
        if indexPath.section == 0, let alertsData = dataProvider.alertsData[cellData.app_name ?? ""] {
            appVC.alertsData = alertsData
        }
        
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}

extension AppsViewController: AlertPopoverShowDelegate {
    func showAlertPopover(for rect: CGRect, sourceView: UIView) {
        guard let indexPath = tableView.indexPath(for: sourceView as? UITableViewCell ?? UITableViewCell()) else { return }
        let alertPopoverViewController = AlertPopoverViewController()
        alertPopoverViewController.modalPresentationStyle = .popover
        let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
        alertPopoverViewController.alertsData = dataProvider.alertsData[cellData.app_name ?? ""]?.filter({$0.isRead == false})
        alertPopoverViewController.appName = cellData.app_name ?? ""
        alertPopoverViewController.delegate = self
        alertPopoverViewController.preferredContentSize = alertPopoverViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if let popoverPresentationController = alertPopoverViewController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = rect
            popoverPresentationController.delegate = self
            self.tabBarController?.tabBar.tintAdjustmentMode = .normal
            present(alertPopoverViewController, animated: true, completion: nil)
        }
    }
}

extension AppsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension AppsViewController: AlertPopoverSelectionDelegate {
    func didSelectAlertId(_ id: String?, appName: String) {
        showProductionAlertScreen(id: id, appName: appName)
    }
    
}

extension AppsViewController: ShowAlertScreenDelegate {
    func showAlertScreen() {
        let alertsScreen = ProductionAlertsViewController()
        //alertsScreen.dataSource = alertsData
        self.navigationController?.pushViewController(alertsScreen, animated: true)
    }
}
