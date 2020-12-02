//
//  ServiceDeskContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class ServiceDeskContactsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var contactsDataSource = [ContactData]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setHardCodeData()
        setUpTableView()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Service Desk Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = 90
        tableView.register(UINib(nibName: "AboutContactsCell", bundle: nil), forCellReuseIdentifier: "AboutContactsCell")
        let tableHeaderView = UIView()
        tableHeaderView.frame.size.height = 24
        tableHeaderView.backgroundColor = .white
        tableView.tableHeaderView = tableHeaderView
    }
    
    private func setHardCodeData() {
        contactsDataSource = [
            ContactData(contactName: "Jane Cooper", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "janecooper@mail.com"),
            ContactData(contactName: "Marvin McKinney", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "marvinmckinney@mail.com"),
            ContactData(contactName: "Ronald Richards", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "ronaldrichards@mail.com")
        ]
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension ServiceDeskContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AboutContactsCell", for: indexPath) as? AboutContactsCell {
            let cellDataSource = contactsDataSource[indexPath.row]
            cell.setUpCell(with: cellDataSource)
            return cell
        }
        return UITableViewCell()
    }
    
}
