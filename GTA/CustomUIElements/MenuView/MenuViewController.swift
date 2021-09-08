//
//  TabBarViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.09.2021.
//

import UIKit

protocol TabBarChangeIndexDelegate {
    func changeToIndex(index: Int)
}

class MenuViewController: UIViewController {

    struct MenuItems {
        var name: String
        var image: UIImage?
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let menuItems: [MenuItems] = [
        MenuItems(name: "Home", image: UIImage(named: "homepage_tab_icon")),
        MenuItems(name: "Service Desk", image: UIImage(named: "helpdesk_tab_icon")),
        MenuItems(name: "Apps", image: UIImage(named: "apps_tab_icon")),
        MenuItems(name: "Collaboration", image: UIImage(named: "collaboration_tab_icon")),
        MenuItems(name: "General", image: UIImage(named: "general_tab_icon")),
        MenuItems(name: "Global Technology Team", image: UIImage(named: "team_contacts_icon")),
    ]
    var delegate: TabBarChangeIndexDelegate?
    var dataProvider = MenuViewControllerDataProvider()
    var selectedTabIdx: Int?
    
    var officeLoadingError: String?
    var officeLoadingIsEnabled = true
    private var lastUpdateDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        tableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTableViewCell")
        tableView.register(UINib(nibName: "OfficeStatusCell", bundle: nil), forCellReuseIdentifier: "OfficeStatusCell")
        
        dataProvider.officeSelectionDelegate = self
        
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            if officeLoadingIsEnabled { loadOfficesData() }
        } else {
            // reloading office cell (because office could be changed on office selection screen)
            if officeLoadingIsEnabled {
                tableView.reloadData()
            }
        }
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func openGTTeamScreen() {
        let contactsViewController = GTTeamViewController()
        //contactsViewController.dataProvider = dataProvider
        self.navigationController?.pushViewController(contactsViewController, animated: true)
    }
 
    private func openOfficeScreen() {
        let selectedOffice = dataProvider.userOffice
        let infoViewController = InfoViewController()
        infoViewController.officeDataProvider = dataProvider
        infoViewController.selectedOfficeData = selectedOffice
        infoViewController.infoType = .office
        infoViewController.selectedOfficeUIUpdateDelegate = self
        infoViewController.title = selectedOffice?.officeName
        self.navigationController?.pushViewController(infoViewController, animated: true)
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

    private func loadOfficesData() {
        var forceOpenOfficeSelectionScreen = false
        officeLoadingError = nil
        tableView.reloadData()
        dataProvider.getCurrentOffice(completion: { [weak self] (errorCode, error, isFromCache) in
            if error == nil && errorCode == 200 {
                self?.dataProvider.getAllOfficesData { [weak self] (errorCode, error) in
                    DispatchQueue.main.async {
                        if error == nil && errorCode == 200 {
                            self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                            if self?.dataProvider.allOfficesDataIsEmpty == true {
                                self?.officeLoadingError = "No data available"
                                self?.lastUpdateDate = nil
                            } else if self?.dataProvider.userOffice == nil {
                                self?.officeLoadingError = "Not Selected"
                                self?.lastUpdateDate = nil
                                forceOpenOfficeSelectionScreen = true
                            } else {
                                self?.officeLoadingError = nil
                            }
                            self?.tableView.reloadData()
                            if forceOpenOfficeSelectionScreen {
                                self?.openOfficeSelectionModalScreen()
                            }
                        } else {
                            self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                            self?.tableView.reloadData()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                    self?.tableView.reloadData()
                }
            }
        })
    }

}
extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 48
        case 1:
            return 40
        default:
            return 101
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return menuItems.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell") as? MenuTableViewCell else { return UITableViewCell() }
            cell.menuLabel.text = menuItems[indexPath.row].name
            cell.menuImage.image = menuItems[indexPath.row].image?.withRenderingMode(.alwaysTemplate)
            cell.menuImage.tintColor = .black
            
            guard let index = selectedTabIdx, index <= 5, index == indexPath.row else { return cell }
            cell.menuLabel.textColor = .red
            cell.menuImage.tintColor = .red
            
            return cell
        case 1:
            let cell = UITableViewCell()
            let grayView = UIView(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: 1))
            cell.addSubview(grayView)
            grayView.backgroundColor = .systemGray6
            
            return cell
        default:
            let data = dataProvider.userOffice
            if let officeData = data {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell else { return UITableViewCell() }
                cell.officeStatusLabel.text = officeData.officeName
                cell.officeAddressLabel.text = officeData.officeLocation?.replacingOccurrences(of: "\u{00A0}", with: " ")
                cell.officeAddressLabel.isHidden = officeData.officeLocation?.isEmpty ?? true
                cell.officeNumberLabel.text = officeData.officePhone
                cell.officeNumberLabel.isHidden = officeData.officePhone?.isEmpty ?? true
                cell.officeErrorLabel.isHidden = true
                cell.officeStatusLabel.accessibilityIdentifier = "HomeScreenOfficeTitleLabel"
                cell.officeAddressLabel.accessibilityIdentifier = "HomeScreenOfficeAddressLabel"
                guard let index = selectedTabIdx, index > 5 else { return cell }
                cell.officeLabel.textColor = .red
                cell.officeStatusLabel.textColor = .red
                
                return cell
            } else {
                if let errorStr = officeLoadingError {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell else { return UITableViewCell() }
                    cell.officeStatusLabel.text = " "
                    cell.officeAddressLabel.text = " "
                    cell.officeAddressLabel.isHidden = false
                    cell.officeNumberLabel.text = " "
                    cell.officeNumberLabel.isHidden = false
                    cell.officeErrorLabel.text = errorStr
                    cell.officeErrorLabel.isHidden = false
                    cell.officeLabel.textColor = .black
                    
                    guard let index = selectedTabIdx, index > 5 else { return cell }
                    cell.officeLabel.textColor = .red
                    cell.officeStatusLabel.textColor = .red
                    
                    return cell
                } else {
                    let loadingCell = createLoadingCell(withBottomSeparator: true, verticalOffset: 54)
                    return loadingCell
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate?.changeToIndex(index: indexPath.row)
        } else if indexPath.section == 2 {
            delegate?.changeToIndex(index: 6)
        }
        closeAction(closeButton)
    }
}

extension MenuViewController: OfficeSelectionDelegate, SelectedOfficeUIUpdateDelegate {
    func officeWasSelected() {
        officeLoadingIsEnabled = false
        updateUIWithSelectedOffice()
        dataProvider.getCurrentOffice(completion: { [weak self] (_, _, _) in
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
            self.tableView.reloadData()
        }
    }
}
