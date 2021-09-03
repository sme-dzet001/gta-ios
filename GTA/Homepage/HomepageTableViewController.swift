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

class HomepageTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var dataProvider: HomeDataProvider?
    var officeLoadingError: String?
    var officeLoadingIsEnabled = true
    
    var dataSource: [HomepageCellData] = []
    private var lastUpdateDate: Date?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        tableView.accessibilityIdentifier = "HomeScreenTableView"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadNewsData()
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
        tableView.register(UINib(nibName: "GlobalAlertCell", bundle: nil), forCellReuseIdentifier: "GlobalProductionAlertCell")
    }
    
    private func loadNewsData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.newsDataIsEmpty {
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
        }
        dataProvider.getGlobalNewsData { [weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.tableView.reloadData()
                } else {
                    let isNoData = dataProvider.newsDataIsEmpty
                    if isNoData {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !isNoData
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
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
    
    /*private func loadOfficesData() {
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
    }*/
    
    deinit {
    }

}

extension HomepageTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 312
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
}

/*extension HomepageTableViewController: OfficeSelectionDelegate, SelectedOfficeUIUpdateDelegate {
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
}*/

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
