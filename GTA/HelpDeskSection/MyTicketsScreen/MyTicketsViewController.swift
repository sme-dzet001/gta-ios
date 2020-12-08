//
//  MyTicketsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit
import PanModal

class MyTicketsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var myTicketsData: [TicketData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
        setHardCodeData()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "My Tickets"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search_icon"), style: .plain, target: self, action: #selector(searchPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = 158
        tableView.register(UINib(nibName: "TicketCell", bundle: nil), forCellReuseIdentifier: "TicketCell")
    }

    private func setHardCodeData() {
        // temp
        let comments = [
            TicketComment(author: "jsmith123", text: "Hello, please reeset my SFTS account access. Thanks!"),
            TicketComment(author: "Help Desk Mario", text: "I have received your request. We will get back to your shortly."),
            TicketComment(author: "Help Desk Mario", text: "We have reset your account. Please clear your caches and saved passwords. Let us know if you have any further issues.")
        ]
        
        myTicketsData = [
            TicketData(status: .closed, number: "ref:_00D70JLCa._500392GtqB:ref", issue: "Account Reset", comments: comments),
            TicketData(status: .open, number: "ref:_22M76JOCa._520391GtqA:ref", issue: "Reactivate Account", comments: comments),
            TicketData(status: .open, number: "ref:_24M76JOCa._570391GtqA:ref", issue: "VPN Issue", comments: comments),
            TicketData(status: .closed, number: "ref:_12M76JOCa._521391GtgB:ref", issue: "System Issue", comments: comments),
            TicketData(status: .open, number: "ref:_01K22POCa._420390GabB:ref", issue: "Account Reset", comments: comments),
            TicketData(status: .open, number: "ref:_02K76JOCa._322390GtgB:ref", issue: "Account Reset", comments: comments)
        ]
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchPressed() {
        // not implemented yet
    }
    
}

extension MyTicketsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myTicketsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TicketCell", for: indexPath) as? TicketCell {
            cell.setUpCell(with: myTicketsData[indexPath.row], hideSeparator: indexPath.row == myTicketsData.count - 1)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MyTicketsHeader.instanceFromNib()
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 2, 5:
            let ticketDetailsVC = SecondTicketDetailsViewController()
            ticketDetailsVC.dataSource = myTicketsData[indexPath.row]
            if !UIDevice.current.iPhone5_se {
                let coefficient: CGFloat = UIDevice.current.iPhone7_8 ? 1.3 : 1.5
                ticketDetailsVC.initialHeight = PanModalHeight.contentHeight(self.view.frame.height / coefficient)
            }
            presentPanModal(ticketDetailsVC)
        default:
            let ticketDetailsVC = TicketDetailsViewController()
            ticketDetailsVC.dataSource = myTicketsData[indexPath.row]
            if !UIDevice.current.iPhone5_se {
                let coefficient: CGFloat = UIDevice.current.iPhone7_8 ? 1.3 : 1.5
                ticketDetailsVC.initialHeight = PanModalHeight.contentHeight(self.view.frame.height / coefficient)
            }
            presentPanModal(ticketDetailsVC)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 88
    }
    
}

struct TicketData {
    var status: TicketStatus
    var number: String?
    var date: Date? = Date()
    var issue: String?
    var comments: [TicketComment]
}

struct TicketComment {
    var author: String?
    var text: String?
    var date: Date? = Date()
}

enum TicketStatus {
    case open
    case closed
}
