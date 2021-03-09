//
//  CollaborationViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.03.2021.
//

import UIKit

class CollaborationViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var dataProvider: CollaborationDataProvider = CollaborationDataProvider()
    
    private var dataSource: [CollaborationCellData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpHardCodeData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        dataProvider.getTeamContacts(appSuite: "Office365") { (_, _, _) in
            
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
    }
    
    private func setUpHardCodeData() {
        dataSource.append(CollaborationCellData(imageName: "contacts_icon", cellTitle: "Team Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil))
    }

}

extension CollaborationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
            let cellData = dataSource[indexPath.row]
            //let cellIsActive = cellData.cellSubtitle != "Oops, something went wrong"
            cell.setUpCell(with: cellData, isActive: true, isNeedCornerRadius: true)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }

//            let contactsScreen = AppContactsViewController()
//            contactsScreen.dataProvider = dataProvider
//            contactsScreen.appName = appName ?? ""
            //navigationController?.pushViewController(contactsScreen, animated: true)
    }
    
}

struct CollaborationCellData: ContactsCellDataProtocol {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
}
