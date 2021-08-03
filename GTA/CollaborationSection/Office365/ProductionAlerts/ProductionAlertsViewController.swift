//
//  ProductionAlertsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.04.2021.
//

import UIKit

class ProductionAlertsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var blurView: UIView!
    
    var dataProvider: MyAppsDataProvider?
    var appName: String?
    var selectedId: String?
    
    var badgeCount: Int {
        return dataProvider?.getProductionAlertsCount() ?? 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        if let id = selectedId {
            showAlertDetails(for: id)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlerts), name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateActiveProductionAlertStatus), name: Notification.Name(NotificationsNames.updateActiveProductionAlertStatus), object: nil)
        self.tabBarController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProductionAlerts()
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let activeProductionAlertId = dataProvider?.activeProductionAlertId {
            showAlertDetails(for: activeProductionAlertId)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.updateActiveProductionAlertStatus), object: nil)
    }
    
    @objc private func getProductionAlerts() {
        if let _ = dataProvider?.activeProductionAlertId {
            getProductionAlertIgnoringCache()
        } else {
            getProductionAlertsWithCache()
        }
    }
    
    private func getProductionAlertsWithCache() {
        guard let _ = appName else { return }
        dataProvider?.getProductionAlerts {[weak self] dataWasChanged, errorCode, error, count in
            DispatchQueue.main.async {
                if error == nil {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func getProductionAlertIgnoringCache() {
        guard let app = appName else { return }
        dataProvider?.getProductionAlertIgnoringCache(for: app, completion: {[weak self] errorCode, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.tableView.reloadData()
                }
            }
        })
    }
    
    private func setUpNavigationItem() {
        navigationController?.navigationBar.barTintColor = UIColor.white
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "\(appName ?? "") Production Alerts"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.title = "Production Alerts"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ProductionAlertCell", bundle: nil), forCellReuseIdentifier: "ProductionAlertCell")
    }
    
    private func showAlertDetails(for id: String) {
        let index = dataProvider?.alertsData[appName ?? ""]?.firstIndex(where: {$0.ticketNumber?.lowercased() == id.lowercased()})
        if let row = index, (dataProvider?.alertsData[appName ?? ""]?.count ?? 0) > row {
            createAndShowDetailsScreenForRow(row)
        } else {
            let detailsVC = ProductionAlertsDetails()
            detailsVC.dataProvider = dataProvider
            presentPanModal(detailsVC)
        }
    }
    
    private func showAlertDetails(for row: Int) {
        guard (dataProvider?.alertsData[appName ?? ""]?.count ?? 0) > row else { return }
        createAndShowDetailsScreenForRow(row)
    }
    
    private func createAndShowDetailsScreenForRow(_ row: Int) {
        let detailsVC = ProductionAlertsDetails()
        detailsVC.dataProvider = dataProvider
        let alertData = dataProvider?.alertsData[appName ?? ""]?[row]
        detailsVC.alertData = alertData
        readAlertAndUpdateTabCount(alert: alertData)
        presentPanModal(detailsVC)
    }
    
    private func readAlertAndUpdateTabCount(alert: ProductionAlertsRow?) {
        if let summary = alert?.summary, UserDefaults.standard.value(forKey: summary.lowercased()) == nil {
            UserDefaults.standard.setValue(summary, forKey: summary.lowercased())
        }
        self.tabBarController?.addProductionAlertsItemBadge(atIndex: 2, value: badgeCount > 0 ? "\(badgeCount)" : nil)
    }
    
    @objc private func updateActiveProductionAlertStatus(notification: NSNotification) {
        guard let activeProductionAlertId = (notification.userInfo as? [String : String] ?? [:])["alertId"] else { return }
        let index = dataProvider?.alertsData[appName ?? ""]?.firstIndex(where: {$0.ticketNumber?.lowercased() == activeProductionAlertId.lowercased()})
        guard let row = index, (dataProvider?.alertsData[appName ?? ""]?.count ?? 0) > row else { return }
        let alertData = dataProvider?.alertsData[appName ?? ""]?[row]
        readAlertAndUpdateTabCount(alert: alertData)
    }
    
    @objc private func backPressed() {
        dataProvider?.forceUpdateProductionAlerts = false
        dataProvider?.activeProductionAlertId = nil
        dataProvider?.activeProductionAlertAppName = nil
        self.navigationController?.popViewController(animated: true)
    }

}

extension ProductionAlertsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.alertsData[appName ?? ""]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductionAlertCell", for: indexPath) as? ProductionAlertCell
        let data = dataProvider?.alertsData[appName ?? ""]
        guard (data?.count ?? 0) > indexPath.row, let cellData = data?[indexPath.row] else { return UITableViewCell() }
        cell?.alertNumberLabel.text = cellData.ticketNumber
        cell?.contentView.backgroundColor = cellData.isRead ? .white : UIColor(hex: 0xF7F7FA)
        cell?.dateLabel.text = cellData.closeDateString == nil ? cellData.startDateString?.getFormattedDateStringForProdAlert() : cellData.closeDateString?.getFormattedDateStringForProdAlert()
        cell?.descriptionLabel.text = cellData.summary
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAlertDetails(for: indexPath.row)
    }
    
}

extension ProductionAlertsViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        dataProvider?.forceUpdateProductionAlerts = false
        dataProvider?.activeProductionAlertId = nil
        dataProvider?.activeProductionAlertAppName = nil
    }
    
}
