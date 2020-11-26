//
//  HelpDeskViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 16.11.2020.
//

import UIKit

class HelpDeskViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var helpDeskCellsData: [HelpDeskCellData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setHelpDeskCellsData()
        navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }

    private func setUpTableView() {
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
    }
    
    private func setHelpDeskCellsData() {
        helpDeskCellsData = [
            HelpDeskCellData(imageName: "quick_help_icon", cellTitle: "Quick Help", cellSubtitle: "Password Resets, MFA Help, Report Security", updatesNumber: nil),
            HelpDeskCellData(imageName: "my_devices_icon", cellTitle: "My Devices", cellSubtitle: "Manage Devices, Request Upgrades, etc", updatesNumber: 5),
            HelpDeskCellData(imageName: "my_tickets_icon", cellTitle: "My Tickets", cellSubtitle: "Help Desk Ticket History", updatesNumber: 3),
            HelpDeskCellData(imageName: "contacts_icon", cellTitle: "Help Desk Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil),
            HelpDeskCellData(imageName: "chat_now_icon", cellTitle: "Chat Now", cellSubtitle: "Chat with Help Desk Member", updatesNumber: nil)
        ]
    }
}

extension HelpDeskViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helpDeskCellsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
            cell.setUpCell(with: helpDeskCellsData[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            let myDevicesVC = MyDevicesViewController()
            navigationController?.pushViewController(myDevicesVC, animated: true)
        } else if indexPath.row == 2 {
            let myTicketsVC = MyTicketsViewController()
            navigationController?.pushViewController(myTicketsVC, animated: true)
        }
    }
    
}

struct HelpDeskCellData {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
}
