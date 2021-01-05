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
    
    var dataProvider: HomeDataProvider?
    var officeLoadingError: String?
        
    var dataSource: [HomepageCellData] = []
    private var lastUpdateDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setHardcodedData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadSpecialAlertsData()
            loadOfficesData()
        }
    }
    
    private func setHardcodedData() {
        dataSource = [HomepageCellData(mainText: "Return to work", additionalText: "Updates on reopenings, precautions, etc...", image: "return_to_work", infoType: .returnToWork)/*, HomepageCellData(mainText: "Desk Finder", additionalText: "Finder a temporary safe work location", image: "desk_finder")*/]
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeStatusCell", bundle: nil), forCellReuseIdentifier: "OfficeStatusCell")
    }
    
    private func loadSpecialAlertsData() {
        dataProvider?.getSpecialAlertsData { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .automatic)
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        }
    }
    
    private func loadOfficesData() {
        officeLoadingError = nil
        tableView.reloadSections(IndexSet(integersIn: 1...1), with: .automatic)
        dataProvider?.getCurrentOffice(completion: { [weak self] (errorCode, error) in
            self?.dataProvider?.getAllOfficesData { [weak self] (errorCode, error) in
                self?.lastUpdateDate = Date().addingTimeInterval(60)
                DispatchQueue.main.async {
                    if error == nil && errorCode == 200 {
                        self?.tableView.reloadSections(IndexSet(integersIn: 1...1), with: .automatic)
                    } else {
                        self?.officeLoadingError = "Offices loading is failed!"
                        self?.tableView.reloadSections(IndexSet(integersIn: 1...1), with: .automatic)
                    }
                }
            }
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dataProvider?.alertsData.count ?? 0
        } else if section == 1 {
            return 1
        } else {
            return dataSource.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let data = dataProvider?.alertsData ?? []
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.separator.isHidden = false
            cell?.iconImageView.image = UIImage(named: "alert_icon")
            cell?.mainLabel.text = data[indexPath.row].alertHeadline
            cell?.descriptionLabel.text = dataProvider?.formatDateString(dateString: data[indexPath.row].alertDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss")
            return cell ?? UITableViewCell()
        } else if indexPath.section == 1 {
            let data = dataProvider?.userOffice
            if let officeData = data {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeStatusCell", for: indexPath) as? OfficeStatusCell
                cell?.officeStatusLabel.text = officeData.officeName
                cell?.officeAddressLabel.text = officeData.officeLocation
                cell?.officeNumberLabel.text = "(480) 555-0103"
                cell?.officeEmailLabel.text = "deanna.curtis@example.com"
                cell?.separator.isHidden = false
                return cell ?? UITableViewCell()
            } else {
                if let errorStr = officeLoadingError {
                    let errorCell = createErrorCell(with: errorStr, textColor: UIColor(hex: 0x8E8E93), withSeparator: true)
                    return errorCell
                } else {
                    let loadingCell = createLoadingCell(withSeparator: true, verticalOffset: 24)
                    return loadingCell
                }
            }
        } else  {
            let data = dataSource[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.separator.isHidden = false
            cell?.iconImageView.image = UIImage(named: data.image ?? "")?.withRenderingMode(data.enabled ? .alwaysOriginal : .alwaysTemplate)
            cell?.iconImageView.tintColor = data.enabled ? nil : UIColor(hex: 0x9B9B9B)
            cell?.mainLabel.text = data.mainText
            cell?.descriptionLabel.text = data.additionalText
            cell?.mainLabel.textColor = data.enabled ? UIColor.black : UIColor(hex: 0x9B9B9B)
            return cell ?? UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            guard let alertsData = dataProvider?.alertsData, indexPath.row < alertsData.count else { return }
            let data = alertsData[indexPath.row]
            let infoViewController = InfoViewController()
            infoViewController.dataProvider = dataProvider
            infoViewController.specialAlertData = data
            infoViewController.infoType = .info
            infoViewController.title = data.alertSubHeadline
            self.navigationController?.pushViewController(infoViewController, animated: true)
        } else if indexPath.section == 1 {
            guard let dataProvider = dataProvider, let selectedOffice = dataProvider.userOffice else { return }
            let infoViewController = InfoViewController()
            infoViewController.dataProvider = dataProvider
            infoViewController.selectedOfficeData = selectedOffice
            infoViewController.infoType = .office
            infoViewController.title = selectedOffice.officeName
            self.navigationController?.pushViewController(infoViewController, animated: true)
        }
    }

}

struct HomepageCellData {
    var mainText: String?
    var additionalText: String? = nil
    var image: String? = nil
    var infoType: infoType = .info
    
    var enabled: Bool {
        return infoType != .returnToWork
    }
}

enum infoType {
    case office
    case info
    case deskFinder
    case returnToWork
}
