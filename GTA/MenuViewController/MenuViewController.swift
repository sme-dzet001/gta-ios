//
//  TabBarViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.09.2021.
//

import UIKit

protocol TabBarChangeIndexDelegate: AnyObject {
    func changeToIndex(index: Int)
    func closeButtonPressed()
    func logoutButtonPressed()
    func menuItemWasSelected(vcToSelect: UIViewController?)
    func moveToRootVC()
}

class MenuViewController: UIViewController {

    struct MenuItems {
        var name: String
        var image: UIImage?
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: UIView!
    
    let menuItems: [MenuItems] = [
        MenuItems(name: "Home", image: UIImage(named: "homepage_tab_icon")),
        MenuItems(name: "Service Desk", image: UIImage(named: "helpdesk_tab_icon")),
        MenuItems(name: "Apps", image: UIImage(named: "apps_tab_icon")),
        MenuItems(name: "Collaboration", image: UIImage(named: "collaboration_tab_icon")),
        MenuItems(name: "General", image: UIImage(named: "general_tab_icon")),
        MenuItems(name: "Global Technology Team", image: UIImage(named: "team_contacts_icon")),
        MenuItems(name: "How Do I?", image: UIImage(named: "chat_bot_icon")),
        MenuItems(name: "Logout", image: UIImage(named: "logout")),
    ]
    var dataProvider = MenuViewControllerDataProvider()
    weak var delegate: TabBarChangeIndexDelegate?
    weak var chatBotDelegate: ChatBotDelegate?
    
    var officeLoadingError: String?
    var officeLoadingIsEnabled = true
    private var lastUpdateDate: Date?
    
    var globalAlertsBadges = 0 {
        didSet {
            tableView.reloadData()
        }
    }
    var productionAlertBadges = 0 {
        didSet {
            tableView.reloadData()
        }
    }
    
    let redColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
    
    var selectedItemIndexPath: IndexPath? {
        didSet {
            guard oldValue != selectedItemIndexPath, let _ = tableView else { return }
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        tableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTableViewCell")
        tableView.register(UINib(nibName: "OfficeStatusCell", bundle: nil), forCellReuseIdentifier: "OfficeStatusCell")
        tableView.cornerRadius = 25
        backgroundView.cornerRadius = 25
        
        dataProvider.officeSelectionDelegate = self
        if UIDevice.current.iPhone5_se {
            tableViewHeightConstraint?.constant = 490
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setTableViewHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setTableViewHeight()
        tableView.alpha = 0
        UIView.animate(withDuration: 0.1, delay: 0.2, animations: {
            self.tableView.alpha = 1
        }, completion: nil)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            if officeLoadingIsEnabled { loadOfficesData() }
        } else {
            // reloading office cell (because office could be changed on office selection screen)
            if officeLoadingIsEnabled {
                tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.1, animations: {
            self.tableView.alpha = 0
        }, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        closeAction()
    }
    
    private func setTableViewHeight() {
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
    }
    
    private func openGTTeamScreen() {
        let contactsViewController = GTTeamViewController()
        //contactsViewController.dataProvider = dataProvider
        self.navigationController?.pushViewController(contactsViewController, animated: true)
    }
    
    @objc func closeAction() {
        dismiss(animated: true, completion: nil)
        delegate?.closeButtonPressed()
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
    
    func selectMenuItem(at indexPath: IndexPath) {
        tableView(tableView, didSelectRowAt: indexPath)
    }

    private func loadOfficesData() {
        var forceOpenOfficeSelectionScreen = false
        officeLoadingError = nil
        setTableViewHeight()
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
                            self?.setTableViewHeight()
                            if forceOpenOfficeSelectionScreen {
                                self?.openOfficeSelectionModalScreen()
                            }
                        } else {
                            self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                            self?.tableView.reloadData()
                            self?.setTableViewHeight()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.officeLoadingError = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                    self?.tableView.reloadData()
                    self?.setTableViewHeight()
                }
            }
        })
    }
}
extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if UIDevice.current.iPhone5_se {
                return 40
            }
            return 48
        case 1:
            if UIDevice.current.iPhone5_se {
                return 30
            }
            return 40
        case 2:
            return UITableView.automaticDimension
        default:
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 16))
        view.backgroundColor = .white
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return 0 }
        return 16
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
            let text = menuItems[indexPath.row].name
            let image = menuItems[indexPath.row].image?.withRenderingMode(.alwaysTemplate)
            
            cell.setupCell(text: text, image: image, globalAlertsBadge: globalAlertsBadges, productionAlertBadge: productionAlertBadges, indexPath: indexPath)
            
            guard let selectedIndexPath = selectedItemIndexPath, selectedIndexPath.section == 0, selectedIndexPath.row <= menuItems.count - 3, selectedIndexPath.row == indexPath.row else { return cell }
            cell.selectCell(color: redColor)
            
            return cell
        case 1:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            let grayView = UIView(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: 1))
            cell.addSubview(grayView)
            grayView.backgroundColor = .systemGray6
            
            return cell
        case 2:
            let data = dataProvider.userOffice
            if let officeData = data {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell else { return UITableViewCell() }
                cell.officeLabel.text = "Office: " + (officeData.officeName ?? "")
                cell.officeAddressLabel.text = officeData.officeLocation?.replacingOccurrences(of: "\u{00A0}", with: " ")
                cell.officeAddressLabel.isHidden = officeData.officeLocation?.isEmpty ?? true
                cell.officeNumberLabel.text = officeData.officePhone
                cell.officeNumberLabel.isHidden = officeData.officePhone?.isEmpty ?? true
                cell.officeErrorLabel.isHidden = true
                cell.officeAddressLabel.accessibilityIdentifier = "HomeScreenOfficeAddressLabel"
                cell.officeLabel.textColor = .black
                guard let section = selectedItemIndexPath?.section, indexPath.section == section else { return cell }
                cell.officeLabel.textColor = redColor
                
                return cell
            } else {
                if let errorStr = officeLoadingError {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell else { return UITableViewCell() }
                    cell.officeAddressLabel.text = " "
                    cell.officeAddressLabel.isHidden = true
                    cell.officeNumberLabel.text = " "
                    cell.officeNumberLabel.isHidden = false
                    cell.officeErrorLabel.text = errorStr
                    cell.officeErrorLabel.isHidden = false
                    cell.officeLabel.textColor = .black
                    
                    guard let selectedIndexPath = selectedItemIndexPath, selectedIndexPath.section == 2, selectedIndexPath.row > menuItems.count - 3 else { return cell }
                    cell.officeLabel.textColor = redColor
                    
                    return cell
                } else {
                    let loadingCell = createLoadingCell(withBottomSeparator: false, verticalOffset: 54)
                    return loadingCell
                }
            }
        default:
            let cell = UITableViewCell()
            let button = UIButton(frame: CGRect(x: tableView.frame.size.width - 50, y: 2, width: 40, height: 40))
            cell.selectionStyle = .none
            button.setImage(UIImage(named: "close_icon_bold"), for: .normal)
            button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
            cell.contentView.addSubview(button)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == menuItems.count - 1 { //Logout
                delegate?.logoutButtonPressed()
                closeAction()
                return
            }
            if indexPath.row == menuItems.count - 2 {
                closeAction()
                chatBotDelegate?.showChatBot()
                return
            }
            if selectedItemIndexPath == indexPath {
                delegate?.moveToRootVC()
                closeAction()
                return
            }
            let vcToSelect = instantiateVC(for: indexPath)
            selectedItemIndexPath = indexPath
            delegate?.menuItemWasSelected(vcToSelect: vcToSelect)
        } else if indexPath.section == 2 {
            if selectedItemIndexPath == indexPath {
                delegate?.moveToRootVC()
                closeAction()
                return
            }
            let vcToSelect = instantiateVC(for: indexPath) as? OfficeOverviewViewController
            vcToSelect?.officeDataProvider = dataProvider
            vcToSelect?.selectedOfficeUIUpdateDelegate = self
            vcToSelect?.title = dataProvider.userOffice?.officeName
            selectedItemIndexPath = indexPath
            delegate?.menuItemWasSelected(vcToSelect: vcToSelect)
        }
        tableView.reloadData()
        closeAction()
    }
    
    private func instantiateVC(for indexPath: IndexPath) -> UIViewController? {
        guard selectedItemIndexPath != indexPath else { return nil }
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let storyBoard: UIStoryboard = UIStoryboard(name: "Home", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (0, 1):
            let storyBoard: UIStoryboard = UIStoryboard(name: "HelpDesk", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (0, 2):
            let storyBoard: UIStoryboard = UIStoryboard(name: "Apps", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (0, 3):
            let storyBoard: UIStoryboard = UIStoryboard(name: "Collaboration", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (0, 4):
            let storyBoard: UIStoryboard = UIStoryboard(name: "GeneralScreen", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (0, 5):
            let storyBoard: UIStoryboard = UIStoryboard(name: "GTTeamStoryboard", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        case (2, 0):
            let storyBoard: UIStoryboard = UIStoryboard(name: "OfficeStoryboard", bundle: nil)
            return storyBoard.instantiateInitialViewController()
        default:
            return nil
        }
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
        DispatchQueue.main.async { [weak self] in
            self?.officeLoadingIsEnabled = true
            self?.loadOfficesData()
        }
     }
    
    private func updateUIWithSelectedOffice() {
        DispatchQueue.main.async { [weak self] in
            self?.officeLoadingError = nil
            self?.setTableViewHeight()
            self?.tableView.reloadData()
        }
    }
}

protocol ChatBotDelegate: AnyObject {
    func showChatBot()
}
