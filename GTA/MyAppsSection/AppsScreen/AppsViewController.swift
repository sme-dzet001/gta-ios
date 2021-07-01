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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        //self.dataProvider.appImageDelegate = self
        setUpNavigationItem()
        setAccessibilityIdentifiers()
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProductionAlerts()
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
        self.tableView.reloadData()
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
    
    @objc private func getProductionAlerts() {
        dataProvider.getProductionAlerts {[weak self] errorCode, error in
            DispatchQueue.main.async {
                if error == nil {
                    let totalCount = self?.dataProvider.alertsData.values.count ?? 0
                    self?.tabBarController?.tabBar.items?[2].badgeValue = totalCount > 0 ? "\(totalCount)" : nil
                    self?.tabBarController?.tabBar.items?[2].badgeColor = UIColor(hex: 0xCC0000)
                }
            }
        }
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
    
    private func showProductionAlertScreen(id: String?, appName: String) {
        guard let id = id else { return }
        let alertsScreen = ProductionAlertsViewController()
        alertsScreen.appName = appName
        alertsScreen.selectedId = id
        alertsScreen.dataProvider = dataProvider
        self.navigationController?.pushViewController(alertsScreen, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
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
                let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
                cell.setUpCell(with: cellData)
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
                if let alerts = dataProvider.alertsData[cellData.app_name ?? ""] {
                    cell.popoverShowDelegate = self
                    cell.showAlertScreenDelegate = self
                    cell.setAlert(alertCount: alerts.count)
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
        let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
        appVC.appName = cellData.app_name ?? ""
        appVC.appTitle = cellData.app_title
        appVC.appImageUrl = cellData.appImage ?? ""
        appVC.appLastUpdateDate = cellData.lastUpdateDate
        appVC.systemStatus = cellData.appStatus
        appVC.dataProvider = dataProvider
        if indexPath.section == 0, let alertsData = dataProvider.alertsData[cellData.app_name ?? ""] {
            appVC.alertsData = alertsData
        }
        
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}

extension AppsViewController: AlertPopoverShowDelegate {
    func showAlertPopover(for rect: CGRect, sourceView: UIView) {
        guard let indexPath = tableView.indexPath(for: sourceView as? UITableViewCell ?? UITableViewCell()) else { return }
        let alertPopoverViewController = AlertPopoverViewController()
        alertPopoverViewController.modalPresentationStyle = .popover
        let cellData = dataProvider.appsData[indexPath.section].cellData[indexPath.row]
        alertPopoverViewController.alertsData = dataProvider.alertsData[cellData.app_name ?? ""]
        alertPopoverViewController.appName = cellData.app_name ?? ""
        alertPopoverViewController.delegate = self
        alertPopoverViewController.preferredContentSize = alertPopoverViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if let popoverPresentationController = alertPopoverViewController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = rect
            popoverPresentationController.delegate = self
            self.tabBarController?.tabBar.tintAdjustmentMode = .normal
            present(alertPopoverViewController, animated: true, completion: nil)
        }
    }
}

extension AppsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension AppsViewController: AlertPopoverSelectionDelegate {
    func didSelectAlertId(_ id: String?, appName: String) {
        showProductionAlertScreen(id: id, appName: appName)
    }
    
}

extension AppsViewController: ShowAlertScreenDelegate {
    func showAlertScreen() {
        let alertsScreen = ProductionAlertsViewController()
        //alertsScreen.dataSource = alertsData
        self.navigationController?.pushViewController(alertsScreen, animated: true)
    }
}
