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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let activeProductionAlertId = dataProvider?.activeProductionAlertId {
            if dataProvider?.alertsData[appName ?? ""] != nil {
                showAlertDetails(for: activeProductionAlertId)
            } else {
                dataProvider?.forceUpdateProductionAlerts = false
                dataProvider?.activeProductionAlertId = nil
                dataProvider?.activeProductionAlertAppName = nil
            }
        }
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
        guard let row = index, (dataProvider?.alertsData[appName ?? ""]?.count ?? 0) > row else { return }
        createAndShowDetailsScreenForRow(row)
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
        self.tabBarController?.tabBar.items?[2].badgeValue = badgeCount > 0 ? "\(badgeCount)" : nil
        self.tabBarController?.tabBar.items?[2].badgeColor = UIColor(hex: 0xCC0000)
    }
    
    @objc private func backPressed() {
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
