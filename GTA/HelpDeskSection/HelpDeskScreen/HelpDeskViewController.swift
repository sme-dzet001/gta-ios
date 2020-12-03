//
//  HelpDeskViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 16.11.2020.
//

import UIKit

class HelpDeskViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    private var dataProvider: HelpDeskDataProvider = HelpDeskDataProvider()
    
    private var helpDeskCellsData: [[HelpDeskCellData]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpHeaderView()
        setUpTableView()
        setHelpDeskCellsData()
        navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setUpHeaderView() {
        let header = HelpDeskHeader.instanceFromNib()
        headerView.addSubview(header)
        header.pinEdges(to: headerView)
    }

    private func setUpTableView() {
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
        tableView.register(UINib(nibName: "HelpDeskContactOptionCell", bundle: nil), forCellReuseIdentifier: "HelpDeskContactOptionCell")
    }
    
    private func setHelpDeskCellsData() {
        helpDeskCellsData = [
            [HelpDeskCellData(imageName: "phone_call_icon", cellTitle: "Call", cellSubtitle: "+1 (212) 833-6767", updatesNumber: nil),
            HelpDeskCellData(imageName: "send_message_icon", cellTitle: "Send Message", cellSubtitle: "helpdesk.request@sonymusic.com", updatesNumber: nil),
            HelpDeskCellData(imageName: "teams_chat_icon", cellTitle: "Teams Chat", cellSubtitle: "Teams mobile app is required", updatesNumber: nil)],
            [HelpDeskCellData(imageName: "quick_help_icon", cellTitle: "Quick Help", cellSubtitle: "Password Resets, MFA Help, Report Security", updatesNumber: nil),
            HelpDeskCellData(imageName: "about_red_icon", cellTitle: "About", cellSubtitle: "Overview of the mission, hours, etc.", updatesNumber: nil),
            HelpDeskCellData(imageName: "contacts_icon", cellTitle: "Service Desk Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil),
            HelpDeskCellData(imageName: "my_tickets_icon", cellTitle: "My Tickets", cellSubtitle: "Help Desk Ticket History", updatesNumber: 3),
            HelpDeskCellData(imageName: "my_devices_icon", cellTitle: "My Devices", cellSubtitle: "Manage Devices, Request Upgrades, etc", updatesNumber: 5)]
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
                cell.setUpCell(with: cellData)
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
                let cellData = helpDeskCellsData[indexPath.section][indexPath.row]
                cell.setUpCell(with: cellData)
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
        guard indexPath.section == 1 else { return }
        if indexPath.row == 0 {
            let quickHelpVC = QuickHelpViewController()
            navigationController?.pushViewController(quickHelpVC, animated: true)
        } else if indexPath.row == 2 {
            let contactsVC = ServiceDeskContactsViewController()
            navigationController?.pushViewController(contactsVC, animated: true)
        } else if indexPath.row == 3 {
            let myTicketsVC = MyTicketsViewController()
            navigationController?.pushViewController(myTicketsVC, animated: true)
        } else if indexPath.row == 4 {
            let myDevicesVC = MyDevicesViewController()
            navigationController?.pushViewController(myDevicesVC, animated: true)
        }
    }
    
}

struct HelpDeskCellData {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
}
