//
//  AboutViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var dataSource: AboutDataSource?
    var details: AppDetailsData?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setHardCodeData()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.white
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AboutInfoCell", bundle: nil), forCellReuseIdentifier: "AboutInfoCell")
        tableView.register(UINib(nibName: "AboutContactsCell", bundle: nil), forCellReuseIdentifier: "AboutContactsCell")
    }
    
    private func setHardCodeData() {
        dataSource = AboutDataSource(description: [DescriptionData(text: details?.appDescription)], contactsData: [ContactData(contactName: "Jane Cooper", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "janecooper@mail.com"), ContactData(contactName: "Marvin McKinney", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "marvinmckinney@mail.com")])
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dataSource?.description.count ?? 0
        } else {
            return dataSource?.contactsData.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let header = AboutContactsHeader.instanceFromNib()
        header.headerTitleLabel.text = "Contacts"
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 1 else { return 0 }
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AboutInfoCell", for: indexPath) as? AboutInfoCell {
            let cellDataSource = dataSource?.description[indexPath.row]
            cell.setUpCell(with: cellDataSource?.text)
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AboutContactsCell", for: indexPath) as? AboutContactsCell {
            let cellDataSource = dataSource?.contactsData[indexPath.row]
            cell.setUpCell(with: cellDataSource)
            return cell
        }
        return UITableViewCell()
    }
}

struct AboutDataSource {
    var description: [DescriptionData]
    var contactsData: [ContactData]
}

struct DescriptionData {
    var text: String?
}

struct ContactData {
    var contactName: String?
    var contactPosition: String?
    var phoneNumber: String?
    var email: String?
}
