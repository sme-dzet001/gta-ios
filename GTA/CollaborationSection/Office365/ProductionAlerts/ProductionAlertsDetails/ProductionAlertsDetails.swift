//
//  ProductionAlertsDetails.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.04.2021.
//

import UIKit
import PanModal

class ProductionAlertsDetails: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: MyAppsDataProvider?
    
    var alertData: ProductionAlertsRow?
    private var dataSource: [[String : String]] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setUpTableView()
        loadProductionAlertsData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if loadProductionAlertsInProgress.loadAllAppsInProgress || loadProductionAlertsInProgress.loadMyAppsInProgress {
            dataProvider?.forceUpdateProductionAlerts = false
            dataProvider?.activeProductionAlertId = nil
            dataProvider?.activeProductionAlertAppName = nil
        }
    }
    
    private var loadProductionAlertsInProgress: (loadAllAppsInProgress: Bool, loadMyAppsInProgress: Bool) = (false, false) {
        didSet {
            if loadProductionAlertsInProgress == (false, false) {
                if let appName = dataProvider?.activeProductionAlertAppName, let alertsData = dataProvider?.alertsData, let alertsDataForApp = alertsData[appName] as? ProductionAlertsResponse, let activeProductionAlertId = dataProvider?.activeProductionAlertId, let alertData = alertsDataForApp.data?.first(where: {$0?.id == activeProductionAlertId}) {
                    self.alertData = alertData
                    setUpDataSource()
                }
                dataProvider?.forceUpdateProductionAlerts = false
                dataProvider?.activeProductionAlertId = nil
                dataProvider?.activeProductionAlertAppName = nil
            }
            tableView.reloadData()
        }
    }
    
    private func loadProductionAlertsData() {
        if let forceUpdateProductionAlerts = dataProvider?.forceUpdateProductionAlerts, forceUpdateProductionAlerts {
            loadProductionAlertsInProgress = (true, true)
            dataProvider?.getAllAppsIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.loadProductionAlertsInProgress.loadAllAppsInProgress = false
                }
            })
            dataProvider?.getMyAppsStatusIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.loadProductionAlertsInProgress.loadMyAppsInProgress = false
                }
            })
        } else {
            dataProvider?.forceUpdateProductionAlerts = false
            dataProvider?.activeProductionAlertId = nil
            dataProvider?.activeProductionAlertAppName = nil
            setUpDataSource()
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AlertDetailsCell", bundle: nil), forCellReuseIdentifier: "AlertDetailsCell")
    }
    
    private func setUpDataSource() {
        if let start = alertData?.start {
            dataSource.append(["Start" : start])
        }
        if let duration = alertData?.duration {
            dataSource.append(["Duration" : duration])
        }
        if let summary = alertData?.summary {
            dataSource.append(["Summary" : summary])
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension ProductionAlertsDetails: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataSource.count > 0) ? dataSource.count : 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = AlertDetailsHeader.instanceFromNib()
        headerView.alertNumberLabel.text = alertData?.id
        headerView.alertTitleLabel.text = alertData?.title
        headerView.setStatus(alertData?.alertStatus)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if loadProductionAlertsInProgress.loadAllAppsInProgress || loadProductionAlertsInProgress.loadMyAppsInProgress {
            return createLoadingCell(withBottomSeparator: false)
        }
        guard dataSource.count > indexPath.row, let key = dataSource[indexPath.row].keys.first else {
            return createErrorCell(with: "No data available")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlertDetailsCell", for: indexPath) as? AlertDetailsCell
        cell?.titleLabel.text = key
        cell?.descriptionLabel.text = dataSource[indexPath.row][key]
        return cell ?? UITableViewCell()
    }
    
}

extension ProductionAlertsDetails: PanModalPresentable {
    
    var panScrollable: UIScrollView? {
        return tableView
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var shortFormHeight: PanModalHeight {
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return PanModalHeight.contentHeight(coefficient - (view.window?.safeAreaInsets.bottom ?? 0))
    }
    
}
