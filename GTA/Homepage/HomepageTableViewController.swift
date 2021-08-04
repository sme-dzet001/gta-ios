//
//  HomepageTableViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit

protocol HomepageMainDelegate: AnyObject {
    func navigateToOfficeStatus()
}

class HomepageTableViewController: UITableViewController {
    
    var dataProvider: HomeDataProvider?
    var officeLoadingError: String?
    var officeLoadingIsEnabled = true
        
    weak var showModalDelegate: ShowGlobalAlertModalDelegate?
    var dataSource: [HomepageCellData] = []
    private var lastUpdateDate: Date?
    private var dismissDidPressed: Bool = false
    private var emergencyOutageLoaded: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.navigationController?.topViewController is HomepageViewController, self.emergencyOutageLoaded {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }
     
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        tableView.accessibilityIdentifier = "HomeScreenTableView"
        NotificationCenter.default.addObserver(self, selector: #selector(getAllAlerts), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getGlobalAlertsIgnoringCache), name: Notification.Name(NotificationsNames.emergencyOutageNotificationDisplayed), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if emergencyOutageLoaded {
            emergencyOutageLoaded = false
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        getAllAlerts()
        dataProvider?.officeSelectionDelegate = self
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadSpecialAlertsData()
            if officeLoadingIsEnabled { loadOfficesData() }
        } else {
            // reloading office cell (because office could be changed on office selection screen)
            if officeLoadingIsEnabled {
                if tableView.dataHasChanged {
                    tableView.reloadData()
                } else {
                    UIView.performWithoutAnimation {
                        tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                    }
                }
            }
        }
    }
    
    private func setAccessibilityIdentifiers() {
        guard let items = self.tabBarController?.tabBar.items else { return }
        for (index, _) in items.enumerated() {
            self.tabBarController?.tabBar.items?[index].accessibilityIdentifier = getIdentifierForTabbarIndex(index)
        }
    }
    
    private func getIdentifierForTabbarIndex(_ index: Int) -> String {
        switch index {
        case 0:
            return "TabBarHomeTab"
        case 1:
            return "TabBarServiceDeskTab"
        case 2:
            return "TabBarAppsTab"
        case 3:
            return "TabBarCollaborationTab"
        case 4:
            return "TabBarGeneralTab"
        default:
            return ""
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeStatusCell", bundle: nil), forCellReuseIdentifier: "OfficeStatusCell")
        tableView.register(UINib(nibName: "GTTeamCell", bundle: nil), forCellReuseIdentifier: "GTTeamCell")
        tableView.register(UINib(nibName: "GlobalAlertCell", bundle: nil), forCellReuseIdentifier: "GlobalAlertCell")
    }
    
    private func loadSpecialAlertsData() {
        let numberOfRows = tableView.numberOfRows(inSection: 1)
        dataProvider?.getSpecialAlertsData { [weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    let doubleCheck = numberOfRows == self?.dataProvider?.alertsData.count
                    if let dataHasChanged = self?.tableView.dataHasChanged, dataHasChanged || !doubleCheck {
                        self?.tableView.reloadData()
                    } else {
                        self?.tableView.reloadSections(IndexSet(integersIn: 2...2), with: .none)
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        }
    }
    
    private func loadOfficesData() {
        var forceOpenOfficeSelectionScreen = false
        officeLoadingError = nil
        if tableView.dataHasChanged {
            tableView.reloadData()
        } else {
            UIView.performWithoutAnimation {
                tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
            }
        }
        dataProvider?.getCurrentOffice(completion: { [weak self] (errorCode, error, isFromCache) in
            if error == nil && errorCode == 200 {
                self?.dataProvider?.getAllOfficesData { [weak self] (errorCode, error) in
                    DispatchQueue.main.async {
                        if error == nil && errorCode == 200 {
                            self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                            if self?.dataProvider?.allOfficesDataIsEmpty == true {
                                self?.officeLoadingError = "No data available"
                                self?.lastUpdateDate = nil
                            } else if self?.dataProvider?.userOffice == nil {
                                self?.officeLoadingError = "Not Selected"
                                self?.lastUpdateDate = nil
                                forceOpenOfficeSelectionScreen = true
                            } else {
                                self?.officeLoadingError = nil
                            }
                            if self?.tableView.dataHasChanged == true {
                                self?.tableView.reloadData()
                            } else {
                                UIView.performWithoutAnimation {
                                    self?.tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                                }
                            }
                            if forceOpenOfficeSelectionScreen {
                                self?.openOfficeSelectionModalScreen()
                            }
                        } else {
                            self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                            if self?.tableView.dataHasChanged == true {
                                self?.tableView.reloadData()
                            } else {
                                UIView.performWithoutAnimation {
                                    self?.tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                                }
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                    if self?.tableView.dataHasChanged == true {
                        self?.tableView.reloadData()
                    } else {
                        UIView.performWithoutAnimation {
                            self?.tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                        }
                    }
                }
            }
        })
    }
    
    @objc private func getGlobalAlerts() {
        dataProvider?.getGlobalAlerts(completion: {[weak self] isFromCache, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.emergencyOutageLoaded = dataWasChanged && !isFromCache
                    if self?.tableView.dataHasChanged == true {
                        self?.tableView.reloadData()
                    } else {
                        UIView.performWithoutAnimation {
                            self?.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
                        }
                    }
                    if let data = self?.dataProvider?.globalAlertsData {
                        switch data.status {
                        case .inProgress:
                            self?.tabBarController?.addAlertItemBadge(atIndex: 0)
                        default:
                            self?.tabBarController?.removeItemBadge(atIndex: 0)
                        }
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        })
    }
    
    @objc private func getGlobalAlertsIgnoringCache() {
        dataProvider?.getGlobalAlertsIgnoringCache {[weak self] _, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if dataWasChanged, error == nil {
                    self?.emergencyOutageLoaded = true
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
    
    private func getGlobalProductionAlerts() {
        dataProvider?.getGlobalProductionAlerts(completion: {[weak self] dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if dataWasChanged {
                    self?.dismissDidPressed = false
                }
                if error == nil && errorCode == 200 {
                    if self?.tableView.dataHasChanged == true {
                        self?.tableView.reloadData()
                    } else {
                        UIView.performWithoutAnimation {
                            self?.tableView.reloadSections(IndexSet(integersIn: 1...1), with: .none)
                        }
                    }
                    if let data = self?.dataProvider?.productionGlobalAlertsData {
                        switch data.status {
                        case .open:
                            if self?.dataProvider?.globalAlertsData?.status != .inProgress {
                                self?.tabBarController?.removeItemBadge(atIndex: 0)
                            }
                        case .inProgress:
                            let eventStarted = data.startDate.timeIntervalSince1970 >= Date().timeIntervalSince1970
                            let eventFinished = data.closeDate.timeIntervalSince1970 + 3600 > Date().timeIntervalSince1970
                            if eventStarted || eventFinished {
                                self?.tabBarController?.addAlertItemBadge(atIndex: 0)
                            }
                        default:
                            return
                        }
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        })
    }
    
    @objc private func getAllAlerts() {
        getGlobalAlerts()
        getGlobalProductionAlerts()
    }
    
    private func openOfficeSelectionModalScreen() {
        let officeLocation = OfficeLocationViewController()
        var statusBarHeight: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 17 : statusBarHeight - 21
        } else {
            statusBarHeight = self.view.bounds.height - UIApplication.shared.statusBarFrame.height
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 17 : statusBarHeight - 21
        }
        officeLocation.title = "Select Sony Music Office Region"
        officeLocation.dataProvider = dataProvider
        officeLocation.forceOfficeSelection = true
        //officeLocation.officeSelectionDelegate = self
        let panModalNavigationController = PanModalNavigationController(rootViewController: officeLocation)
        panModalNavigationController.setNavigationBarHidden(true, animated: true)
        panModalNavigationController.initialHeight = self.tableView.bounds.height - statusBarHeight
        panModalNavigationController.forceOfficeSelection = true
        
        presentPanModal(panModalNavigationController)
    }
    
    private func openAlertScreen(for indexPath: IndexPath) {
        guard let alertsData = dataProvider?.alertsData, indexPath.row < alertsData.count else { return }
        let data = alertsData[indexPath.row]
        let infoViewController = InfoViewController()
        infoViewController.dataProvider = dataProvider
        infoViewController.specialAlertData = data
        infoViewController.infoType = .info
        infoViewController.title = data.alertHeadline
        self.navigationController?.pushViewController(infoViewController, animated: true)
    }
    
    private func openOfficeScreen(for indexPath: IndexPath) {
        guard let dataProvider = dataProvider, let selectedOffice = dataProvider.userOffice else { return }
        let infoViewController = InfoViewController()
        infoViewController.dataProvider = dataProvider
        infoViewController.selectedOfficeData = selectedOffice
        infoViewController.infoType = .office
        infoViewController.selectedOfficeUIUpdateDelegate = self
        infoViewController.title = selectedOffice.officeName
        self.navigationController?.pushViewController(infoViewController, animated: true)
    }
    
    private func openGTTeamScreen() {
        let contactsViewController = GTTeamViewController()
        contactsViewController.dataProvider = dataProvider
        self.navigationController?.pushViewController(contactsViewController, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

}

extension HomepageTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
//        case 0:
//            let alert = dataProvider?.globalAlertsData
//            if alert == nil || (alert?.isExpired ?? true) || alert?.status == .open {
//                return 0
//            }
//            return 1
        case 2:
            return dataProvider?.alertsData.count ?? 0
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let alert = dataProvider?.globalAlertsData
            if alert == nil || (alert?.isExpired ?? true) || alert?.status == .open {
                return 0
            }
            return 80
        case 1:
            let alert = dataProvider?.productionGlobalAlertsData
            if alert == nil || (alert?.isExpired ?? true) || alert?.status == .open || dismissDidPressed {
                return 0
            }
            return 80
        case 2, 3:
            return 80
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertCell", for: indexPath) as? GlobalAlertCell
            guard let alert = dataProvider?.globalAlertsData else { return UITableViewCell() }
            guard !alert.isExpired else { return UITableViewCell() }
            cell?.alertLabel.text = alert.alertTitle ?? "Emergency Outage"
            if alert.status == .closed {
                cell?.setAlertOff()
            } else {
                cell?.setAlertOn()
            }
            return cell ?? UITableViewCell()
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAlertCell", for: indexPath) as? GlobalAlertCell
            guard let alert = dataProvider?.productionGlobalAlertsData else { return UITableViewCell() }
            guard !alert.isExpired else { return UITableViewCell() }
            cell?.alertLabel.text = alert.issueReason ?? "Global Production Alert"
            cell?.closeButton.isHidden = false
            cell?.delegate = self
            cell?.setAlertBannerForGlobalProdAlert(startDate: alert.startDate, advancedTime: Double(alert.sendPushBeforeStartInHr ?? 0.0), status: alert.status)
            return cell ?? UITableViewCell()
        } else if indexPath.section == 2 {
            let data = dataProvider?.alertsData ?? []
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.separator.isHidden = false
            cell?.iconImageView.image = UIImage(named: "info_icon")
            cell?.mainLabel.text = data[indexPath.row].alertTitle
            cell?.mainLabel.textColor = .black
            if let date = data[indexPath.row].alertDate?.getFormattedDateStringForMyTickets() { //dataProvider?.formatDateString(dateString: data[indexPath.row].alertDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss") {
                cell?.descriptionLabel.text = date
            } else {
                cell?.descriptionLabel.text = nil
                cell?.setMainLabelAtCenter()
            }
            cell?.mainLabel.accessibilityIdentifier = "HomeScreenAlertTitleLabel"
            return cell ?? UITableViewCell()
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GTTeamCell", for: indexPath) as? GTTeamCell
            return cell ?? UITableViewCell()
        } else if indexPath.section == 4 {
            let data = dataProvider?.userOffice
            if let officeData = data {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell
                cell?.officeStatusLabel.text = officeData.officeName
                cell?.officeAddressLabel.text = officeData.officeLocation?.replacingOccurrences(of: "\u{00A0}", with: " ")
                cell?.officeAddressLabel.isHidden = officeData.officeLocation?.isEmpty ?? true
                cell?.officeNumberLabel.text = officeData.officePhone
                cell?.officeNumberLabel.isHidden = officeData.officePhone?.isEmpty ?? true
                cell?.officeEmailLabel.text = officeData.officeEmail
                cell?.officeEmailLabel.isHidden = officeData.officeEmail?.isEmpty ?? true
                cell?.officeErrorLabel.isHidden = true
                cell?.separator.isHidden = false
                cell?.arrowImage.isHidden = false
                cell?.officeStatusLabel.accessibilityIdentifier = "HomeScreenOfficeTitleLabel"
                cell?.officeAddressLabel.accessibilityIdentifier = "HomeScreenOfficeAddressLabel"
                return cell ?? UITableViewCell()
            } else {
                if let errorStr = officeLoadingError {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell
                    cell?.officeStatusLabel.text = " "
                    cell?.officeAddressLabel.text = " "
                    cell?.officeAddressLabel.isHidden = false
                    cell?.officeNumberLabel.text = " "
                    cell?.officeNumberLabel.isHidden = false
                    cell?.officeEmailLabel.text = " "
                    cell?.officeEmailLabel.isHidden = false
                    cell?.officeErrorLabel.text = errorStr
                    cell?.officeErrorLabel.isHidden = false
                    cell?.separator.isHidden = false
                    cell?.arrowImage.isHidden = true
                    return cell ?? UITableViewCell()
                } else {
                    let loadingCell = createLoadingCell(withBottomSeparator: true, verticalOffset: 54)
                    return loadingCell
                }
            }
        } else  {
            let data = dataSource[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.separator.isHidden = false
            cell?.iconImageView.image = UIImage(named: data.image ?? "")?.withRenderingMode(data.enabled ? .alwaysOriginal : .alwaysTemplate)
            cell?.iconImageView.tintColor = data.enabled ? nil : UIColor(hex: 0x9B9B9B)
            cell?.mainLabel.text = data.mainText
            cell?.descriptionLabel.text = data.additionalText
            cell?.mainLabel.textColor = data.enabled ? UIColor.black : UIColor(hex: 0x9B9B9B)
            return cell ?? UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            showModalDelegate?.showGlobalAlertModal(isProdAlert: false)
        case 1:
            showModalDelegate?.showGlobalAlertModal(isProdAlert: true)
        case 2:
            openAlertScreen(for: indexPath)
        case 3:
            openGTTeamScreen()
        default:
            openOfficeScreen(for: indexPath)
        }
    }
    
}

extension HomepageTableViewController: OfficeSelectionDelegate, SelectedOfficeUIUpdateDelegate {
    func officeWasSelected() {
        officeLoadingIsEnabled = false
        updateUIWithSelectedOffice()
        dataProvider?.getCurrentOffice(completion: { [weak self] (_, _, _) in
            self?.officeLoadingIsEnabled = true
        })
    }
    
    func updateUIWithNewSelectedOffice() {
        DispatchQueue.main.async {
            self.officeLoadingIsEnabled = true
            self.loadOfficesData()
        }
    }
    
    private func updateUIWithSelectedOffice() {
        DispatchQueue.main.async {
            self.officeLoadingError = nil
            if self.tableView.dataHasChanged {
                self.tableView.reloadData()
            } else {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                }
            }
        }
    }
}

extension HomepageTableViewController: DismissAlertDelegate {
    func closeAlertDidPressed() {
        let alert = UIAlertController(title: nil, message: "Are you sure? (temp message)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismissDidPressed = true
            self.tableView.reloadSections(IndexSet(integersIn: 1...1), with: .none)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

struct HomepageCellData {
    var mainText: String?
    var additionalText: String? = nil
    var image: String? = nil
    var infoType: infoType = .info
    
    var enabled: Bool {
        return infoType != .returnToWork
    }
}

enum infoType {
    case office
    case info
    case deskFinder
    case returnToWork
}

protocol SelectedOfficeUIUpdateDelegate: AnyObject {
    func updateUIWithNewSelectedOffice()
}
