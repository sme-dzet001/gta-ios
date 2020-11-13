//
//  ApplicationStatusViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 11.11.2020.
//

import UIKit
import PanModal

class ApplicationStatusViewController: UIViewController, ShowAlertDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [AppsDataSource] = []
    var appName: String? = ""
    var systemStatus: SystemStatus = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setHardCodeData()
        setUpTableView()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1)//UIColor(red: 229.0 / 255.0, green: 229.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0)
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = appName
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "SystemUpdatesCell", bundle: nil), forCellReuseIdentifier: "SystemUpdatesCell")
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "SystemStatusChartCell", bundle: nil), forCellReuseIdentifier: "SystemStatusChartCell")
        
    }
    
    private func setHardCodeData() {
        let bellData = UIImage(named: "report_icon")
        let loginHelpData = UIImage(named: "login_help")
        
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData:[CellData(mainText: "Report Issue", additionalText: "Report Outages, System Issues", image: bellData?.pngData(), systemStatus: .none), CellData(mainText: "Login Help", additionalText: "Reset Account Accesss & login Assistance", image: loginHelpData?.pngData(), systemStatus: .none)]), AppsDataSource(sectionName: "System Updates", description: nil, cellData: [CellData(mainText: "08/15/20 – 06:15 +5 GMT", additionalText: "System restore", systemStatus: .none), CellData(mainText: "08/15/20 – 06:15 +5 GMT", additionalText: "Sheduled maintanence", systemStatus: .other), CellData(mainText: "08/15/20 – 06:15 +5 GMT", additionalText: "System restore",  systemStatus: .offline), CellData(mainText: "08/15/20 – 06:15 +5 GMT", additionalText: "AWS outage reported",  systemStatus: .offline)])]
    }

    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension ApplicationStatusViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let statusHeader = SystemStatusHeader.instanceFromNib()
            statusHeader.setUpSignalViews(for: systemStatus)
            return statusHeader
        }
        let header = AppsTableViewHeader.instanceFromNib()
        header.descriptionLabel.text = dataSource[section].description
        header.headerTitleLabel.text = dataSource[section].sectionName
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 60
        }
        if UIDevice.current.iPhone5_se {
            return self.view.frame.height / 2.5
        }
        return self.view.frame.height / 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.setUpCell(with: dataSource[indexPath.section].cellData[indexPath.row], isNeedCornerRadius: indexPath.row == 0)
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SystemUpdatesCell", for: indexPath) as? SystemUpdatesCell {
            cell.setUpCell(with: dataSource[indexPath.section].cellData[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let reportScreen = ReportScreenViewController()
        reportScreen.delegate = self
        presentPanModal(reportScreen)
        
    }
    
}

protocol ShowAlertDelegate: class {
    func showAlert(title: String?, message: String?)
}
