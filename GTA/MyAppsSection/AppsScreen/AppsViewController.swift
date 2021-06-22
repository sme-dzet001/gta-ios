//
//  AppsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit
import Kingfisher

class AppsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
   // var dataSource: [AppsDataSource] = []
    
    private var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    private var myAppsLastUpdateDate: Date?
    private var allAppsLastUpdateDate: Date?
    private var allAppsLoadingError: Error?
    private var myAppsLoadingError: Error?
    private var alertsData: ProductionAlertsResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        //self.dataProvider.appImageDelegate = self
        setUpNavigationItem()
        setAccessibilityIdentifiers()
        getProductionAlerts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
        startAnimation()
        if allAppsLastUpdateDate == nil || Date() >= allAppsLastUpdateDate ?? Date() {
            self.getAllApps()
        }
        if myAppsLastUpdateDate == nil || Date() >= myAppsLastUpdateDate ?? Date() {
            self.getMyApps()
        }
        activateStatusRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataProvider.invalidateStatusRefresh()
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "My Apps"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
    }
    
    private func activateStatusRefresh() {
        dataProvider.activateStatusRefresh {[weak self] (isNeedToRefresh) in
            guard isNeedToRefresh else { return }
            self?.getAllApps()
        }
    }
    
    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "AppsScreenTableView"
        self.navigationItem.titleView?.accessibilityIdentifier = "AppsScreenTitleView"
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
                } else if !isFromCache, let isEmpty = self?.dataProvider.appsData.isEmpty, !isEmpty {
                    self?.stopAnimation()
                } else if !isFromCache, let isEmpty = self?.dataProvider.appsData.isEmpty, isEmpty, self?.allAppsLoadingError != nil {
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
                    self?.errorLabel.isHidden = true
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
    
    private func getProductionAlerts() {
        alertsData = ProductionAlertsResponse(meta: nil, data: [ProductionAlertsRow(id: "DPSX-169", title: "GRPS/MMT/Gold Downtime. Weds 10th Feb, 2020 6am EST/12pm CEST", date: "2021-02-10", status: "open", start: "2021-02-10 15:30 EDT", duration: "4hrs", summary: "GRPS/MMT/Gold Downtime. Weds 10th Feb, 2020 6am EST/12pm CEST - 90 mins A downtime is required for the next GROS release. Pleease log out of the application before thiss time. Users will be notified when systems are back up. Thank you GRPS/MMT/Gold Teams"), ProductionAlertsRow(id: "DPSX-169", title: "GRPS/MMT/Gold Downtime. Weds 10th Feb, 2020 6am EST/12pm CEST", date: "2021-02-10", status: "open", start: "2021-02-10 15:30 EDT", duration: "4hrs", summary: "GRPS/MMT/Gold Downtime. Weds 10th Feb, 2020 6am EST/12pm CEST - 90 mins A downtime is required for the next GROS release. Pleease log out of the application before thiss time. Users will be notified when systems are back up. Thank you GRPS/MMT/Gold Teams")])
    }
    
    private func startAnimation() {
        guard dataProvider.appsData.isEmpty else { return }
        self.errorLabel.isHidden = true
        self.tableView.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        guard dataProvider.myAppsStatusData != nil || myAppsLoadingError != nil else { return }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.errorLabel.isHidden = !(self.dataProvider.appsData.isEmpty && self.allAppsLoadingError != nil)
            self.errorLabel.text = (self.allAppsLoadingError as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
            self.tableView.alpha = !self.dataProvider.appsData.isEmpty ? 1 : 0
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "ApplicationCell", bundle: nil), forCellReuseIdentifier: "ApplicationCell")
    }
    
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
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !dataProvider.appsData.isEmpty {
            let header = AppsTableViewHeader.instanceFromNib()
            header.descriptionLabel.text = dataProvider.appsData[section].description
            header.headerTitleLabel.text = dataProvider.appsData[section].sectionName
            header.headerTitleLabel.accessibilityIdentifier = "AppsScreenHeaderTitleLabel"
            header.descriptionLabel.accessibilityIdentifier = "AppsScreenHeaderDescriptionLabel"
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let error = allAppsLoadingError as? ResponseError, dataProvider.appsData.isEmpty {
            return createErrorCell(with: error.localizedDescription)
        }
        if indexPath.section == 0, let error = myAppsLoadingError as? ResponseError, let isEmpty = dataProvider.myAppsStatusData?.data?.isEmpty, isEmpty {
            return createErrorCell(with: error.localizedDescription)
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationCell", for: indexPath) as? ApplicationCell {
            if indexPath.section < dataProvider.appsData.count, indexPath.row < dataProvider.appsData[indexPath.section].cellData.count {
                cell.setUpCell(with: dataProvider.appsData[indexPath.section].cellData[indexPath.row])
                //cell.startAnimation()
                cell.appIcon.accessibilityIdentifier = "AppsScreenCellIcon"
                cell.appStatus.accessibilityIdentifier = "AppsScreenAppStatus"
                cell.appName.accessibilityIdentifier = "AppsScreenAppNameTitleLabel"
                let url = URL(string: dataProvider.appsData[indexPath.section].cellData[indexPath.row].appImage ?? "")
                if let urlString = url?.absoluteString, !urlString.isEmptyOrWhitespace() {
                cell.appIcon.kf.indicatorType = .activity
                cell.appIcon.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                    //cell.stopAnimation()
                    switch result {
                    case .success(let resData):
                        cell.appIcon.image = resData.image
                    case .failure(let error):
                        if !error.isNotCurrentTask {
                            cell.showFirstChar()
                        }
                    }
                })
                } else {
                    cell.showFirstChar()
                }
                if indexPath.section == 0, indexPath.row == 0 {
                    cell.setAlert(alertCount: alertsData?.data?.count)
                }
                cell.separator.isHidden = indexPath.row != dataProvider.appsData[indexPath.section].cellData.count - 1
            } else {
                print("!!!error my apps cell no data!!!!")
                return createErrorCell(with: "No data available")
            }
            return cell
        }
        return UITableViewCell()
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
        guard indexPath.section < dataProvider.appsData.count else { return }
        guard !dataProvider.appsData[indexPath.section].cellData.isEmpty else { return }
        let appVC = ApplicationStatusViewController()
        appVC.appName = dataProvider.appsData[indexPath.section].cellData[indexPath.row].app_name
        appVC.appTitle = dataProvider.appsData[indexPath.section].cellData[indexPath.row].app_title
        appVC.appImageUrl = dataProvider.appsData[indexPath.section].cellData[indexPath.row].appImage ?? ""
        appVC.appLastUpdateDate = dataProvider.appsData[indexPath.section].cellData[indexPath.row].lastUpdateDate
        appVC.systemStatus = dataProvider.appsData[indexPath.section].cellData[indexPath.row].appStatus
        appVC.dataProvider = dataProvider
        appVC.alertsData = alertsData
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}
//
//extension AppsViewController: AppImageDelegate {
//
//    func setImage(with data: Data?, for appName: String?, error: Error?) {
//        DispatchQueue.main.async {
//            let sectionIndex = self.dataProvider.appsData.firstIndex(where: {$0.cellData.contains(where: {$0.app_name == appName})})
//            if let _ = sectionIndex {
//                let rowIndex = self.dataProvider.appsData[sectionIndex!].cellData.firstIndex(where: {$0.app_name == appName})
//                guard let _ = rowIndex else { return }
//                self.dataProvider.appsData[sectionIndex!].cellData[rowIndex!].appImageData.imageData = data
//                var isFailed: Bool = false
//                if let _ = data, let _ = UIImage(data: data!) {
//                    isFailed = false
//                } else {
//                    isFailed = true
//                }
//                self.dataProvider.appsData[sectionIndex!].cellData[rowIndex!].appImageData.imageStatus = isFailed ? .failed : .loaded
//                self.setCellImageView(for: IndexPath(row: rowIndex!, section: sectionIndex!))
//            }
//        }
//    }
//
//    private func setCellImageView(for indexPath: IndexPath) {
//        if let cell = self.tableView.cellForRow(at: indexPath) as? ApplicationCell {
//            cell.setUpCell(with: self.dataProvider.appsData[indexPath.section].cellData[indexPath.row])
//        }
//    }
//
//}
