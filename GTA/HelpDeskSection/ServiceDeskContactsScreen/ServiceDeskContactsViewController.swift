//
//  ServiceDeskContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class ServiceDeskContactsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var contactsDataSource = [ServiceDeskContact]()

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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ServiceDeskContactCell", bundle: nil), forCellReuseIdentifier: "ServiceDeskContactCell")
    }
    
    private func setHardCodeData() {
        contactsDataSource = [
            ServiceDeskContact(photoImageName: "jane_cooper_photo", contactName: "Jane Cooper", contactPosition: "Administrator", description: "Nulla Lorem mollit cupidatat irure. Laborum magna nulla duis ullamco cillum dolor.", email: "janecooper@mail.com", location: "US - New York"),
            ServiceDeskContact(photoImageName: "ralph_edwards_photo", contactName: "Ralph Edwards", contactPosition: "Administrator", description: "Aliqua id fugiat nostrud irure ex duis ea quis id quis ad et. Sunt qui esse pariatur duis deserunt mollit dolore cillum minim tempor enim.", email: "janecooper@mail.com", location: "US - New York"),
            ServiceDeskContact(photoImageName: "leslie_alexander_photo", contactName: "Leslie Alexander", contactPosition: "Administrator", description: "Nulla Lorem mollit cupidatat irure. Laborum magna nulla duis ullamco cillum dolor.", email: "janecooper@mail.com", location: "US - New York")
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
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceDeskContactCell", for: indexPath) as? ServiceDeskContactCell {
            let cellDataSource = contactsDataSource[indexPath.row]
            cell.setUpCell(with: cellDataSource)
            return cell
        }
        return UITableViewCell()
    }
    
}

struct ServiceDeskContact {
    var photoImageName: String?
    var contactName: String?
    var contactPosition: String?
    var description: String?
    var email: String?
    var location: String?
}
