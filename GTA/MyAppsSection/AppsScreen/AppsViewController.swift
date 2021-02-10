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
    private var allAppsLoadingError: Error?
    private var myAppsLoadingError: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        self.dataProvider.appImageDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
        startAnimation()
        if allAppsLastUpdateDate == nil || Date() >= allAppsLastUpdateDate ?? Date() {
            self.getAllApps()
        }
        if myAppsLastUpdateDate == nil || Date() >= myAppsLastUpdateDate ?? Date() {
            self.getMyApps()
        }
    }
    
    private func getMyApps() {
        myAppsLoadingError = nil
        dataProvider.getMyAppsStatus {[weak self] (errorCode, error, isFromCache) in
            self?.myAppsLoadingError = isFromCache ? nil : error
            DispatchQueue.main.async {
                if error == nil, errorCode == 200, let isEmpty = self?.dataProvider.appsData.isEmpty {
                    if !isFromCache {
                        self?.myAppsLastUpdateDate = Date().addingTimeInterval(15)
                    }
                    if !isEmpty {
                        self?.stopAnimation()
                    }
                    //let appInfo = self?.dataProvider.appsData.map({$0.cellData}).reduce([], {$0 + $1})
                    //self?.dataProvider.getImageData(for: appInfo ?? [])
                } else if !isFromCache, let isEmpty = self?.dataProvider.appsData.isEmpty, !isEmpty {
                    self?.stopAnimation()
                }
            }
        }
    }
    
    private func getAllApps() {
        allAppsLoadingError = nil
        dataProvider.getAllApps {[weak self] (errorCode, error, isFromCache) in
            self?.allAppsLoadingError = isFromCache ? nil : error
            DispatchQueue.main.async {
                if error == nil, errorCode == 200, let appsData = self?.dataProvider.appsData.first {
                    if !isFromCache {
                        self?.allAppsLastUpdateDate = Date().addingTimeInterval(60)
                    }
                    if !appsData.cellData.isEmpty || self?.myAppsLoadingError != nil {
                        self?.stopAnimation()
                    }
                    //let appInfo = self?.dataProvider.appsData.map({$0.cellData}).reduce([], {$0 + $1})
                    //self?.dataProvider.getImageData(for: appInfo ?? [])
                } else if !isFromCache {
                    self?.stopAnimation()
                }
            }
        }
    }
    
    private func startAnimation() {
        guard dataProvider.appsData.isEmpty else { return }
        self.tableView.alpha = 0
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.center = CGPoint(x: UIScreen.main.bounds.width  / 2,
                                                y: UIScreen.main.bounds.height / 2.5)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        guard dataProvider.myAppsStatusData != nil || myAppsLoadingError != nil else { return }
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
    
//    private func setHardCodeData() {
//        let serviceAlertIsAlreadyPresent = dataProvider.appsData.contains(where: { (appsDataSource) -> Bool in
//            appsDataSource.cellData.first?.app_name == "Service Alert: VPN Outage"
//        })
//        guard !serviceAlertIsAlreadyPresent else { return }
//        dataProvider.appsData.insert(AppsDataSource(sectionName: nil, description: nil, cellData: [AppInfo(app_name: "Service Alert: VPN Outage", app_title: "10:30 +5 GTM Wed 15", app_icon: nil, appStatus: .none, app_is_active: false, imageData: nil)]), at: 0)
////        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: [AppInfo(app_name: "Service Alert: VPN Outage", app_title: "10:30 +5 GTM Wed 15", app_icon: nil, appStatus: .none, app_is_active: false, imageData: nil)])]
////
//    }
    
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = allAppsLoadingError, dataProvider.appsData.isEmpty {
            return 1
        }
        return dataProvider.appsData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = allAppsLoadingError, dataProvider.appsData.isEmpty {
            return 1
        }
        if dataProvider.appsData[section].sectionName == "My Apps" {
            let myAppsDataIsEmpty = dataProvider.appsData[section].cellData.isEmpty
            if let _ = myAppsLoadingError, myAppsDataIsEmpty {
                return 1
            }
            return dataProvider.appsData[section].cellData.count
        }
        return dataProvider.appsData[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if allAppsLoadingError != nil && dataProvider.appsData.isEmpty {
            return tableView.frame.height
        }
//        if indexPath.section == 0 {
//            return 80
//        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let error = allAppsLoadingError as? ResponseError, dataProvider.appsData.isEmpty {
            return createErrorCell(with: error.localizedDescription)
        }
        /*if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.setUpCell(with: dataProvider.appsData[indexPath.section].cellData[indexPath.row])
            return cell
         } else*/ if indexPath.section == 0, let error = myAppsLoadingError as? ResponseError, let isEmpty = dataProvider.myAppsStatusData?.data?.isEmpty, isEmpty {
            return createErrorCell(with: error.localizedDescription)
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as? ApplicationCell {
            if indexPath.section < dataProvider.appsData.count, indexPath.row < dataProvider.appsData[indexPath.section].cellData.count {
                cell.setUpCell(with: dataProvider.appsData[indexPath.section].cellData[indexPath.row])
            } else {
                print("!!!error my apps cell no data!!!!")
                return createErrorCell(with: "No data available")
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if allAppsLoadingError == nil && !dataProvider.appsData.isEmpty {
            let header = AppsTableViewHeader.instanceFromNib()
            header.descriptionLabel.text = dataProvider.appsData[section].description
            header.headerTitleLabel.text = dataProvider.appsData[section].sectionName
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if allAppsLoadingError != nil && dataProvider.appsData.isEmpty {
            return 0
        }
        /*guard section != 0 else { return 0 }
        if section == 2 {
            return 80
        }
        return 60*/
        if section == 1 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard allAppsLoadingError == nil, myAppsLoadingError == nil else { return }
        guard indexPath.section < dataProvider.appsData.count else { return }
        guard !dataProvider.appsData[indexPath.section].cellData.isEmpty else { return }
        let appVC = ApplicationStatusViewController()
        appVC.appName = dataProvider.appsData[indexPath.section].cellData[indexPath.row].app_name
        appVC.appTitle = dataProvider.appsData[indexPath.section].cellData[indexPath.row].app_title
        appVC.appImageUrl = dataProvider.appsData[indexPath.section].cellData[indexPath.row].appImageData.app_icon ?? ""
        appVC.appLastUpdateDate = dataProvider.appsData[indexPath.section].cellData[indexPath.row].lastUpdateDate
        appVC.systemStatus = dataProvider.appsData[indexPath.section].cellData[indexPath.row].appStatus
        appVC.dataProvider = dataProvider
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}

extension AppsViewController: AppImageDelegate {
    
    func setImage(with data: Data?, for appName: String?, error: Error?) {
        DispatchQueue.main.async {
            let sectionIndex = self.dataProvider.appsData.firstIndex(where: {$0.cellData.contains(where: {$0.app_name == appName})})
            if let _ = sectionIndex {
                let rowIndex = self.dataProvider.appsData[sectionIndex!].cellData.firstIndex(where: {$0.app_name == appName})
                guard let _ = rowIndex else { return }
                self.dataProvider.appsData[sectionIndex!].cellData[rowIndex!].appImageData.imageData = data
                var isFailed: Bool = false
                if let _ = data, let _ = UIImage(data: data!) {
                    isFailed = false
                } else {
                    isFailed = true
                }
                self.dataProvider.appsData[sectionIndex!].cellData[rowIndex!].appImageData.imageStatus = isFailed ? .failed : .loaded
                self.setCellImageView(for: IndexPath(row: rowIndex!, section: sectionIndex!))
            }
        }
    }
    
    private func setCellImageView(for indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? ApplicationCell {
            cell.setUpCell(with: self.dataProvider.appsData[indexPath.section].cellData[indexPath.row])
        }
    }
    
}
