//
//  AppsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class AppsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
   // var dataSource: [AppsDataSource] = []
    
    private var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var myAppsLastUpdateDate: Date?
    private var allAppsLastUpdateDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        self.dataProvider.appImageDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
        if allAppsLastUpdateDate == nil || Date() >= allAppsLastUpdateDate ?? Date() {
            self.getAllApps()
        }
        if myAppsLastUpdateDate == nil || Date() >= myAppsLastUpdateDate ?? Date() {
            self.getMyApps()
        }
    }
    
    private func getMyApps() {
        dataProvider.getMyAppsStatus {[weak self] (errorCode, error, isFromServer) in
            self?.myAppsLastUpdateDate = Date().addingTimeInterval(15)
            if error != nil || errorCode != 200 {
                // error handling
            } else if let isEmpty = self?.dataProvider.appsData.isEmpty, !isEmpty {
                self?.stopAnimation()
                self?.setHardCodeData()
                let appInfo = self?.dataProvider.appsData.map({$0.cellData}).reduce([], {$0 + $1})
                self?.dataProvider.getImageData(for: appInfo ?? [])
            }
        }
    }
    
    private func getAllApps() {
        dataProvider.getAllApps {[weak self] (errorCode, error) in
            self?.allAppsLastUpdateDate = Date().addingTimeInterval(60)
            if error != nil || errorCode != 200 {
                // error handling
            } else if let isEmpty = self?.dataProvider.appsData.isEmpty, !isEmpty {
                self?.stopAnimation()
                self?.setHardCodeData()
                let appInfo = self?.dataProvider.appsData.map({$0.cellData}).reduce([], {$0 + $1})
                self?.dataProvider.getImageData(for: appInfo ?? [])
            }
        }
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.center = CGPoint(x: UIScreen.main.bounds.width  / 2,
                                                y: UIScreen.main.bounds.height / 2.5)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.alpha = 1
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "ApplicationCell", bundle: nil), forCellReuseIdentifier: "ApplicationCell")
    }
    
    private func setHardCodeData() {
        dataProvider.appsData.insert(AppsDataSource(sectionName: nil, description: nil, cellData: [AppInfo(app_name: "Service Alert: VPN Outage", app_title: "10:30 +5 GTM Wed 15", app_icon: nil, appStatus: .none, app_is_active: false, imageData: nil)]), at: 0)
//        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: [AppInfo(app_name: "Service Alert: VPN Outage", app_title: "10:30 +5 GTM Wed 15", app_icon: nil, appStatus: .none, app_is_active: false, imageData: nil)])]
//
    }
    
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataProvider.appsData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.appsData[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.setUpCell(with: dataProvider.appsData[indexPath.section].cellData[indexPath.row])
        return cell
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as? ApplicationCell {
            cell.setUpCell(with: dataProvider.appsData[indexPath.section].cellData[indexPath.row], hideStatusView: dataProvider.appsData[indexPath.section].sectionName == "Other Apps")
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = AppsTableViewHeader.instanceFromNib()
        header.descriptionLabel.text = dataProvider.appsData[section].description
        header.headerTitleLabel.text = dataProvider.appsData[section].sectionName
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
        guard dataProvider.appsData[indexPath.section].sectionName != "Other Apps" else { return }
        let appVC = ApplicationStatusViewController()
        appVC.appName = dataProvider.appsData[indexPath.section].cellData[indexPath.row].app_name
        appVC.systemStatus = dataProvider.appsData[indexPath.section].cellData[indexPath.row].appStatus
        appVC.dataProvider = dataProvider
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}

extension AppsViewController: AppImageDelegate {
    
    func setImage(with data: Data?, for appName: String?) {
        DispatchQueue.main.async {
            for (index, element) in self.dataProvider.appsData.enumerated() {
                for (cellDataIndex, cellDataObject) in element.cellData.enumerated() {
                    if cellDataObject.app_name == appName, self.dataProvider.appsData[index].cellData[cellDataIndex].imageData == nil {
                        self.dataProvider.appsData[index].cellData[cellDataIndex].imageData = data
                        self.dataProvider.appsData[index].cellData[cellDataIndex].isImageDataEmpty = data == nil
                        self.setCellImageView(for: IndexPath(row: cellDataIndex, section: index))
                    }
                }
            }
        }
    }
    
    private func setCellImageView(for indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? ApplicationCell {
            cell.setUpCell(with: self.dataProvider.appsData[indexPath.section].cellData[indexPath.row], hideStatusView:self.dataProvider.appsData[indexPath.section].sectionName == "Other Apps")
        }
    }
    
}
