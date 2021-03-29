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
    
    private var helpDeskCellsData: [[HelpDeskCellData]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpHeaderView()
        setUpTableView()
        //setHelpDeskCellsData()
        navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getServiceDeskStatus()
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            startAnimation()
            self.getHelpDeskData()
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
        activateStatusRefresh()
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
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.alpha = 1
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func setUpHeaderView() {
        DispatchQueue.main.async {
            let header = HelpDeskHeader.instanceFromNib()
            self.headerView.addSubview(header)
            header.pinEdges(to: self.headerView)
            header.setStatus(statusData: self.statusResponse)
        }
    }

    private func setUpTableView() {
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
        tableView.register(UINib(nibName: "HelpDeskContactOptionCell", bundle: nil), forCellReuseIdentifier: "HelpDeskContactOptionCell")
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
        let teamsChatCellSubtitle = dataResponse?.teamsChatLink != nil ? "Teams mobile app is required" : (errorDesc ?? "no teams chat link")
        helpDeskCellsData = [
            [HelpDeskCellData(imageName: "phone_call_icon", cellTitle: "Call", cellSubtitle: phoneCellSubtitle, updatesNumber: nil),
             HelpDeskCellData(imageName: "send_message_icon", cellTitle: "Send Message", cellSubtitle: emailCellSubtitle, updatesNumber: nil),
             HelpDeskCellData(imageName: "teams_chat_icon", cellTitle: "Teams Chat", cellSubtitle: teamsChatCellSubtitle, updatesNumber: nil)],
            [HelpDeskCellData(imageName: "quick_help_icon", cellTitle: "Quick Help", cellSubtitle: "Password Resets, MFA Help, etc.", updatesNumber: nil),
            HelpDeskCellData(imageName: "about_red_icon", cellTitle: "About", cellSubtitle: aboutCellSubtitle, updatesNumber: nil),
            HelpDeskCellData(imageName: "contacts_icon", cellTitle: "Service Desk Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil),
            HelpDeskCellData(imageName: "my_tickets_icon", cellTitle: "My Tickets", cellSubtitle: "Help Desk Ticket History", updatesNumber: 6)]
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
                let cellIsActive = cellData.cellSubtitle != nil && cellData.cellSubtitle != "Oops, something went wrong" && cellData.cellSubtitle != "no phone number" && cellData.cellSubtitle != "no email" && cellData.cellSubtitle != "no teams chat link"
                cell.setUpCell(with: cellData, isActive: cellIsActive)
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
                let cellData = helpDeskCellsData[indexPath.section][indexPath.row]
                let cellIsActive = cellData.cellSubtitle != "Oops, something went wrong"
                cell.setUpCell(with: cellData, isActive: cellIsActive)
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor(hex: 0xF7F7FA)
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 10 : 0
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
                guard let msTeamsLink = sectionData[indexPath.row].cellSubtitle, msTeamsLink != "Oops, something went wrong", msTeamsLink != "no teams chat link" else { return }
                openMSTeamsChat()
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
            guard let cellSubtitle = helpDeskCellsData[indexPath.section][indexPath.row].cellSubtitle, cellSubtitle != "Oops, something went wrong" else { return }
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
    
    private func openMSTeamsChat() {
        if let chatLink = dataResponse?.teamsChatLink, let addressURL = URL(string: chatLink.replacingOccurrences(of: "https://", with: "msteams://").replacingOccurrences(of: "http://", with: "msteams://")) {
            UIApplication.shared.open(addressURL, options: [:], completionHandler: { (isSuccess) in
                if !isSuccess {
                    self.needMSTeamsAppAlert()
                }
            })
        } else if let addressURL = URL(string: "msteams://teams.microsoft.com/l/team/19%3a77f2b169349f449da4be0ebda3c44aee%40thread.tacv2/conversations?groupId=e7cf5b23-9d73-469f-8f4e-022835c554dd&tenantId=f0aff3b7-91a5-4aae-af71-c63e1dda2049") {
            UIApplication.shared.open(addressURL, options: [:], completionHandler: { (isSuccess) in
                if !isSuccess {
                    self.needMSTeamsAppAlert()
                }
            })
        }
    }
    
    private func needMSTeamsAppAlert() {
        let alert = UIAlertController(title: "Teams App Required", message: "Teams mobile app is required", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open App Store", style: .default, handler: { (_) in
            if let url = URL(string: "itms-apps://apps.apple.com/ua/app/microsoft-teams/id1113153706") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
