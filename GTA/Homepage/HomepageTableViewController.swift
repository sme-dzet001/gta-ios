//
//  HomepageTableViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit

protocol HomepageMainDelegate: AnyObject {
    func navigateToOfficeStatus()
}

class HomepageTableViewController: UITableViewController {
        
    var dataSource: [HomepageCellData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setHardcodedData()
    }
    
    private func setHardcodedData() {
        dataSource = [HomepageCellData(mainText: "COVID-19 Info Updated", additionalText: "10:30 +5 GTM Wed 15", image: "alert_icon"), HomepageCellData(mainText: "Closed", address: OfficeAddress(address: "9 Derry Street, London, W8 5HY, United Kingdom", phoneNumber: "(480) 555-0103", email: "deanna.curtis@example.com"), infoType : .office), HomepageCellData(mainText: "Return to work", additionalText: "Updates on reopenings, precautions, etc...", image: "return_to_work"), HomepageCellData(mainText: "Desk Finder", additionalText: "Finder a temporary safe work location", image: "desk_finder")]
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeStatusCell", bundle: nil), forCellReuseIdentifier: "OfficeStatusCell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = dataSource[indexPath.row]
        if let _ = data.address {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell
            cell?.officeStatusLabel.text = data.mainText
            cell?.officeAddressLabel.text = data.address?.address
            cell?.officeNumberLabel.text = data.address?.phoneNumber
            cell?.officeEmailLabel.text = data.address?.email
            cell?.separator.isHidden = false
            return cell ?? UITableViewCell()
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.separator.isHidden = false
            cell?.iconImageView.image = UIImage(named: data.image ?? "")
            cell?.mainLabel.text = data.mainText
            cell?.descriptionLabel.text = data.additionalText
            return cell ?? UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < 2 else { return }
        let data = dataSource[indexPath.row]
        let infoViewController = InfoViewController()
        infoViewController.infoType = data.infoType
        infoViewController.title = data.infoType == .office ? "Sony Music UK" : "What is the current situation?"
        self.navigationController?.pushViewController(infoViewController, animated: true)
    }

}

struct HomepageCellData {
    var mainText: String?
    var additionalText: String? = nil
    var image: String? = nil
    var address: OfficeAddress? = nil
    var infoType: infoType = .info
    
}

struct OfficeAddress {
    var address: String
    var phoneNumber: String
    var email: String
}

enum infoType {
    case office
    case info
    case deskFinder
    case returnToWork
}
