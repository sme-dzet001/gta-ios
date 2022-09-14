//
//  HelpDeskViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 16.11.2020.
//

import UIKit

class HelpDeskViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    private var lastUpdateDate: Date?
    
    private var dataProvider: HelpDeskDataProvider = HelpDeskDataProvider()
    
    var dataResponse: HelpDeskResponse?
    private var statusResponse: HelpDeskStatus = HelpDeskStatus()
    var helpDeskResponseError: Error?
    weak var logoutDelegate: LogoutDelegate?
    private var helpDeskCellsData: [[HelpDeskCellData]] = []
    weak var ticketsNumberDelegate: TicketsNumberDelegate?
    private var numberOfTickets: Int? {
        let count = dataProvider.myTickets?.filter({$0.status != .closed}).count ?? 0
        return count > 0 ? count : nil
    }
    
    #if HelpDeskUAT || HelpDeskDev || HelpDeskProd
    private var isNeedLogoutView: Bool = true
    #else
    private var isNeedLogoutView: Bool = false
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpHeaderView()
        setUpTableView()
        //setHelpDeskCellsData()
        navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
        setUpUIElementsForNewVersion()
        addLogoutViewIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getServiceDeskStatus()
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            startAnimation()
            self.getHelpDeskData()
        }
        getMyTickets()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        activateStatusRefresh()
    }
    
    private func getMyTickets() {
        dataProvider.getMyTickets {[weak self] (_, _, dataWasChanged) in
            DispatchQueue.main.async {
                self?.ticketsNumberDelegate?.ticketNumberUpdated(self?.numberOfTickets)
                //if dataWasChanged { self?.ticketsNumberDelegate?.ticketNumberUpdated(self?.numberOfTickets) }
            }
        }
    }
    
    private func addLogoutViewIfNeeded() {
        guard isNeedLogoutView else { return }
        let logoutView = LogoutView.instanceFromNib()
        logoutView.translatesAutoresizingMaskIntoConstraints = false
        logoutView.setUpView()
        logoutView.logoutDelegate = self
        self.view.addSubview(logoutView)
        NSLayoutConstraint.activate([
            logoutView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            logoutView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            logoutView.heightAnchor.constraint(equalToConstant: 80),
            logoutView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10)
        ])
    }
    
    private func activateStatusRefresh() {
        dataProvider.activateStatusRefresh {[weak self] (isNeedToRefresh) in
            guard isNeedToRefresh else { return }
            self?.getServiceDeskStatus()
        }
    }
    
    private func getHelpDeskData() {
        dataProvider.getHelpDeskData { [weak self] (response, code, error, isFromCache) in
            if let helpDeskResponse = response {
                self?.lastUpdateDate = isFromCache ? nil : Date().addingTimeInterval(60)
                self?.dataResponse = helpDeskResponse
                self?.statusResponse.hoursOfOperation = response?.hoursOfOperation
            }
            self?.setUpHeaderView()
            self?.helpDeskResponseError = error
            self?.setHelpDeskCellsData()
            self?.stopAnimation()
        }
    }
    
    private func getServiceDeskStatus() {
        dataProvider.getGSDStatus {[weak self] (status, errorCode, error, isFromCache) in
            if error == nil, let _ = status {
                self?.statusResponse.statusString = status?.serviceDeskStatus
            }
            self?.setUpHeaderView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataProvider.invalidateStatusRefresh()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func startAnimation() {
        guard dataResponse == nil else { return }
        self.tableView.alpha = 0
        self.activityIndicator.center = CGPoint(x: UIScreen.main.bounds.width  / 2,
                                                y: UIScreen.main.bounds.height / 1.98)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.tableView.alpha = 1
            self?.activityIndicator.stopAnimating()
        }
    }
    
    private func setUpHeaderView() {
        DispatchQueue.main.async { [weak self] in
            guard let headerView = self?.headerView, let response = self?.statusResponse else { return }
            let header = HelpDeskHeader.instanceFromNib()
            header.accessibilityIdentifier = "ServiceDeskHeaderView"
            header.titleLabel.accessibilityIdentifier = "ServiceDeskHeaderViewTitleLabel"
            header.hoursOfOperationLabel.accessibilityIdentifier = "ServiceDeskHeaderHoursOfOperationLabel"
            header.statusLabel.accessibilityIdentifier = "ServiceDeskHeaderStatusLabel"
            headerView.addSubview(header)
            header.pinEdges(to: headerView)
            header.setStatus(statusData: response)
        }
    }

    private func setUpTableView() {
        tableView.rowHeight = 80
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
        tableView.register(UINib(nibName: "HelpDeskContactOptionCell", bundle: nil), forCellReuseIdentifier: "HelpDeskContactOptionCell")
        tableView.accessibilityIdentifier = "ServiceDeskTableView"
    }
    
    private func setHelpDeskCellsData() {
        var serverErrorWasHappened: Bool
        switch (helpDeskResponseError as? ResponseError) {
        case .serverError, .parsingError:
            serverErrorWasHappened = true
        default:
            serverErrorWasHappened = false
        }
        let errorDesc = serverErrorWasHappened ? (helpDeskResponseError as? ResponseError)?.localizedDescription : nil
        let aboutCellSubtitle = (dataResponse == nil && errorDesc != nil) ? errorDesc : "Overview of the mission, hours, etc."
        let phoneCellSubtitle = dataResponse?.serviceDeskPhoneNumber ?? errorDesc ?? "no phone number"
        let emailCellSubtitle = dataResponse?.serviceDeskEmail ?? errorDesc ?? "no email"
        let teamsChatCellSubtitle = "A web browser is required"
        helpDeskCellsData = [
            [HelpDeskCellData(imageName: "phone_call_icon", cellTitle: "Call", cellSubtitle: phoneCellSubtitle, updatesNumber: nil),
             HelpDeskCellData(imageName: "send_message_icon", cellTitle: "Send Message", cellSubtitle: emailCellSubtitle, updatesNumber: nil),
             HelpDeskCellData(imageName: "teams_chat_icon", cellTitle: "Chat with a Tech", cellSubtitle: teamsChatCellSubtitle, updatesNumber: nil)],
            [HelpDeskCellData(imageName: "quick_help_icon", cellTitle: "Quick Help", cellSubtitle: "Password Resets, MFA Help, etc.", updatesNumber: nil),
            HelpDeskCellData(imageName: "info_icon", cellTitle: "About", cellSubtitle: aboutCellSubtitle, updatesNumber: nil),
            HelpDeskCellData(imageName: "contacts_icon", cellTitle: "Service Desk Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil),
            HelpDeskCellData(imageName: "my_tickets_icon", cellTitle: "My Tickets", cellSubtitle: "Help Desk Ticket History", updatesNumber: numberOfTickets)]
            //HelpDeskCellData(imageName: "my_devices_icon", cellTitle: "My Devices", cellSubtitle: "Manage Devices, Request Upgrades, etc.", updatesNumber: 5)]
        ]
    }
}

extension HelpDeskViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return helpDeskCellsData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helpDeskCellsData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskContactOptionCell", for: indexPath) as? HelpDeskContactOptionCell {
                let cellData = helpDeskCellsData[indexPath.section][indexPath.row]
                let cellIsActive = cellData.cellSubtitle != nil && cellData.cellSubtitle != "Oops, something went wrong" && cellData.cellSubtitle != "no phone number" && cellData.cellSubtitle != "no email"
                cell.setUpCell(with: cellData, isActive: cellIsActive)
                cell.cellTitle.accessibilityIdentifier = "ServiceDeskContactCellTitleLabel"
                cell.cellSubtitle.accessibilityIdentifier = "ServiceDeskContactCellSubtitleLabel"
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
                var cellData = helpDeskCellsData[indexPath.section][indexPath.row]
                if cellData.cellTitle == "My Tickets" {
                    ticketsNumberDelegate = cell
                    cellData.updatesNumber = numberOfTickets
                }
                var cellIsNotActive = cellData.cellSubtitle == "Oops, something went wrong"
                var isAboutCellNoData = false
                if indexPath.row == 1, let rows = dataResponse?.data?.rows {
                    cellIsNotActive = dataResponse?.serviceDeskDesc == nil || rows.isEmpty
                    isAboutCellNoData = cellIsNotActive
                } else if indexPath.row == 1, dataResponse?.serviceDeskDesc == nil, !cellIsNotActive {
                    cellIsNotActive = true
                    isAboutCellNoData = true
                }
                cell.setUpCell(with: cellData, isActive: !cellIsNotActive)
                if cellIsNotActive && isAboutCellNoData {
                    cell.setTitleAtCenter()
                }
                cell.cellTitle.accessibilityIdentifier = "ServiceDeskCellTitleLabel"
                cell.cellSubtitle.accessibilityIdentifier = "ServiceDeskCellSubtitleLabel"
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let separatorFooter = UIView()
        separatorFooter.backgroundColor = UIColor(hex: 0xF7F7FA)
        return separatorFooter
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let sectionData: [HelpDeskCellData] = helpDeskCellsData.count != 0 ? helpDeskCellsData[indexPath.section] : []
            switch indexPath.row {
            case 0:
                guard let number = sectionData[indexPath.row].cellSubtitle, number != "Oops, something went wrong", number != "no phone number" else { return }
                makeCallWithNumber(number)
            case 1:
                guard let email = sectionData[indexPath.row].cellSubtitle, email != "Oops, something went wrong", email != "no email" else { return }
                makeEmailForAddress(email)
            case 2:
                openTeamsChat()
            default:
                return
            }
        }
        guard indexPath.section == 1 else { return }
        if indexPath.row == 0 {
            let quickHelpVC = QuickHelpViewController()
            quickHelpVC.dataProvider = dataProvider
            navigationController?.pushViewController(quickHelpVC, animated: true)
        } else if indexPath.row == 1 {
            let cellData = helpDeskCellsData[indexPath.section][indexPath.row]
            let cellIsNotActive = cellData.cellSubtitle == "Oops, something went wrong" || dataResponse?.serviceDeskDesc == nil
            guard let _ = cellData.cellSubtitle, !cellIsNotActive else { return }
            let aboutVC = ServiceDeskAboutViewController()
            let aboutData = (imageUrl: dataResponse?.serviceDeskIcon, desc: dataResponse?.serviceDeskDesc)
            aboutVC.aboutData = aboutData
            aboutVC.dataProvider = dataProvider
            navigationController?.pushViewController(aboutVC, animated: true)
        } else if indexPath.row == 2 {
            let contactsVC = ServiceDeskContactsViewController()
            contactsVC.dataProvider = dataProvider
            navigationController?.pushViewController(contactsVC, animated: true)
        } else if indexPath.row == 3 {
            let myTicketsVC = MyTicketsViewController()
            myTicketsVC.dataProvider = dataProvider
            navigationController?.pushViewController(myTicketsVC, animated: true)
        } else if indexPath.row == 4 {
            let myDevicesVC = MyDevicesViewController()
            navigationController?.pushViewController(myDevicesVC, animated: true)
        }
    }
    
    private func makeCallWithNumber(_ number: String?) {
        if let _ = number?.components(separatedBy: ",").first, let numberURL = URL(string: "tel://" + number!.filter("+0123456789.".contains)) {
            UIApplication.shared.open(numberURL, options: [:], completionHandler: nil)
        }
    }
    
    private func makeEmailForAddress(_ address: String?) {
        if let _ = address, let addressURL = URL(string: "mailto:" + address!) {
            UIApplication.shared.open(addressURL, options: [:], completionHandler: nil)
        }
    }
    
    private func openTeamsChat() {
        let stringUrl = "https://sonymusicentertainment.sharepoint.com/sites/GlobalISTComms/SitePages/Chat.aspx"
        guard let url = URL(string: stringUrl) else { return }
        UIApplication.shared.open(url)
    }
}

extension HelpDeskViewController: LogoutDelegate {
    func logoutDidPressed() {
        logoutDelegate?.logoutDidPressed()
    }
}

struct HelpDeskCellData: ContactsCellDataProtocol {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
}

struct HelpDeskStatus {
    var statusString: String?
    var hoursOfOperation: String?
    var status: SystemStatus {
        return SystemStatus(status: statusString)
    }
}

protocol ContactsCellDataProtocol {
    var imageName: String? {get set}
    var cellTitle: String? {get set}
    var cellSubtitle: String? {get set}
    var updatesNumber: Int? {get set}
}

protocol TicketsNumberDelegate: AnyObject {
    func ticketNumberUpdated(_ number: Int?)
}

protocol LogoutDelegate: AnyObject {
    func logoutDidPressed()
}
