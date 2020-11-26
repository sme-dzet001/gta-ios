//
//  AppsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class AppsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [AppsDataSource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setHardCodeData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "ApplicationCell", bundle: nil), forCellReuseIdentifier: "ApplicationCell")
    }
    
    private func setHardCodeData() {
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData:[CellData(mainText: "Service Alert: VPN Outage", additionalText: "10:30 +5 GTM Wed 15", systemStatus: .none)]), AppsDataSource(sectionName: "My Apps", description: nil, cellData: [CellData(mainText: "AOMA", systemStatus: .online), CellData(mainText: "PROMO PORTAL", systemStatus: .other), CellData(mainText: "SFTS", systemStatus: .offline)]), AppsDataSource(sectionName: "Other Apps", description: "Request Access Permission", cellData:[CellData(mainText: "DX", systemStatus: .online), CellData(mainText: "Delivery Dashboard", systemStatus: .other)])]
    }
    
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.setUpCell(with: dataSource[indexPath.section].cellData[indexPath.row])
        return cell
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as? ApplicationCell {
            cell.setUpCell(with: dataSource[indexPath.section].cellData[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = AppsTableViewHeader.instanceFromNib()
        header.descriptionLabel.text = dataSource[section].description
        header.headerTitleLabel.text = dataSource[section].sectionName
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section != 0 else { return 0 }
        if section == 2 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != 0 else { return }
        let appVC = ApplicationStatusViewController()
        appVC.appName = dataSource[indexPath.section].cellData[indexPath.row].mainText
        appVC.systemStatus = dataSource[indexPath.section].cellData[indexPath.row].systemStatus
        self.navigationController?.pushViewController(appVC, animated: true)
    }
    
}

struct AppsDataSource {
    var sectionName: String?
    var description: String?
    var cellData: [CellData]
    var metricsData: MetricsData? = nil
}

struct CellData {
    var mainText: String?
    var additionalText: String? = nil
    var image: Data? = nil
    var systemStatus: SystemStatus
}

enum SystemStatus {
    case online
    case offline
    case other // temporary
    case none
}

struct MetricsData {
    var dailyData: [ChartData]
    var weeklyData: [ChartData]
    var monthlyData: [ChartData]
}

struct ChartData {
    var legendTitle: String?
    var periodFullTitle: String?
    var value: Int?
}
