//
//  ApplicationStatusViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 11.11.2020.
//

import UIKit
import PanModal

enum MetricsPeriod {
    case daily
    case weekly
    case monthly
}

class ApplicationStatusViewController: UIViewController, ShowAlertDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    var dataSource: [AppsDataSource] = []
    var appDetailsData: AppDetailsData?
    var appName: String? = ""
    var systemStatus: SystemStatus = .none
    var selectedMetricsPeriod: MetricsPeriod = .weekly
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setHardCodeData()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: 0xF9F9FB)
        if appDetailsData == nil {
            startAnimation()
        }
        dataProvider.getAppDetailsData(for: appName) { [weak self] (detailsData, _, error) in
            self?.appDetailsData = detailsData
            self?.stopAnimation()
        }
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.center = CGPoint(x: view.frame.size.width  / 2,
                                                y: view.frame.size.height / 2)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async {
            self.setUpNavigationItem()
            self.tableView.reloadData()
            self.tableView.alpha = 1
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpNavigationItem() {
        self.navigationItem.title = self.appDetailsData?.appTitle
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "SystemUpdatesCell", bundle: nil), forCellReuseIdentifier: "SystemUpdatesCell")
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "MetricStatsCell", bundle: nil), forCellReuseIdentifier: "MetricStatsCell")
    }
    
    private func setHardCodeData() {
        let bellData = UIImage(named: "report_icon")
        let loginHelpData = UIImage(named: "login_help")
        let aboutData = UIImage(named: "about_icon")
        
        let metricsData = MetricsData(
            dailyData: [ChartData(legendTitle: "18/11/20", periodFullTitle: "18 November 2020", value: 85), ChartData(legendTitle: "17/11/20", periodFullTitle: "17 November 2020", value: 62), ChartData(legendTitle: "16/11/20", periodFullTitle: "16 November 2020", value: 105), ChartData(legendTitle: "15/11/20", periodFullTitle: "15 November 2020", value: 100), ChartData(legendTitle: "14/11/20", periodFullTitle: "14 November 2020", value: 70), ChartData(legendTitle: "13/11/20", periodFullTitle: "13 November 2020", value: 95), ChartData(legendTitle: "12/11/20", periodFullTitle: "12 November 2020", value: 100)],
            weeklyData: [ChartData(legendTitle: "18 Nov W/E", periodFullTitle: "18 Nov W/E", value: 690), ChartData(legendTitle: "11 Nov W/E", periodFullTitle: "11 Nov W/E", value: 705), ChartData(legendTitle: "4 Nov W/E", periodFullTitle: "4 Nov W/E", value: 740), ChartData(legendTitle: "28 Oct W/E", periodFullTitle: "28 Oct W/E", value: 520), ChartData(legendTitle: "21 Oct W/E", periodFullTitle: "21 Oct W/E", value: 730), ChartData(legendTitle: "14 Oct W/E", periodFullTitle: "14 Oct W/E", value: 720), ChartData(legendTitle: "7 Oct W/E", periodFullTitle: "7 Oct W/E", value: 430)],
            monthlyData: [ChartData(legendTitle: "11/2020", periodFullTitle: "November 2020", value: 5000), ChartData(legendTitle: "10/2020", periodFullTitle: "October 2020", value: 5450), ChartData(legendTitle: "9/2020", periodFullTitle: "September 2020", value: 5900), ChartData(legendTitle: "8/2020", periodFullTitle: "August 2020", value: 5300), ChartData(legendTitle: "7/2020", periodFullTitle: "July 2020", value: 4100), ChartData(legendTitle: "6/2020", periodFullTitle: "June 2020", value: 5100), ChartData(legendTitle: "5/2020", periodFullTitle: "May 2020", value: 2050)]
        )
        
        let firstSection = [AppInfo(app_id: 0, app_name: "Report Outages, System Issues", app_title: "Report Issue", app_icon: "", appStatus: .none, app_is_active: true, imageData: bellData?.pngData()), AppInfo(app_id: 0, app_name: "Reset Account Access & login Assistance", app_title: "Login Help", app_icon: "", appStatus: .none, app_is_active: true, imageData: loginHelpData?.pngData()), AppInfo(app_id: 0, app_name: "Description and list of app contacts", app_title: "About", app_icon: "", appStatus: .none, app_is_active: true, imageData: aboutData?.pngData())]
        
        let secondSection = [AppInfo(app_id: 0, app_name: "08/15/20 – 06:15 +5 GMT", app_title: "System restore", app_icon: "", appStatus: .none, app_is_active: true, imageData: nil), AppInfo(app_id: 0, app_name: "08/15/20 – 06:15 +5 GMT", app_title: "Scheduled maintenance", app_icon: "", appStatus: .none, app_is_active: true, imageData: nil), AppInfo(app_id: 0, app_name: "08/15/20 – 06:15 +5 GMT", app_title: "System restore", app_icon: "", appStatus: .none, app_is_active: true, imageData: nil), AppInfo(app_id: 0, app_name: "08/15/20 – 06:15 +5 GMT", app_title: "AWS outage reported", app_icon: "", appStatus: .none, app_is_active: true, imageData: nil)]
                
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: firstSection, metricsData: nil), AppsDataSource(sectionName: "System Updates", description: nil, cellData: secondSection), AppsDataSource(sectionName: "Stats", description: nil, cellData: [], metricsData: metricsData)]
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
        if let metricsData = dataSource[section].metricsData {
            switch selectedMetricsPeriod {
            case .daily:
                return metricsData.dailyData.count
            case .weekly:
                return metricsData.weeklyData.count
            case .monthly:
                return metricsData.monthlyData.count
            }
        }
        return dataSource[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let statusHeader = SystemStatusHeader.instanceFromNib()
            statusHeader.systemStatus = systemStatus
            return statusHeader
        } else if let metricsData = dataSource[section].metricsData {
            let metricStatsHeader = MetricStatsHeader.instanceFromNib()
            metricStatsHeader.delegate = self
            metricStatsHeader.setUpHeaderData(selectedPeriod: selectedMetricsPeriod)
            metricStatsHeader.setChartData(selectedPeriod: selectedMetricsPeriod, data: metricsData)
            return metricStatsHeader
        }
        let header = AppsTableViewHeader.instanceFromNib()
        header.descriptionLabel.text = dataSource[section].description
        header.headerTitleLabel.text = dataSource[section].sectionName
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if UIDevice.current.iPhone5_se {
                return self.view.frame.height / 2.5
            }
            return self.view.frame.height / 3
        } else if let _ = dataSource[section].metricsData {
            return 380
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataArray = dataSource[indexPath.section].cellData
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell {
            cell.separator.isHidden = indexPath.row == dataArray.count - 1
            cell.setUpCell(with: dataArray[indexPath.row], isNeedCornerRadius: indexPath.row == 0)
            return cell
        }
        if let metricsData = dataSource[indexPath.section].metricsData, let cell = tableView.dequeueReusableCell(withIdentifier: "MetricStatsCell", for: indexPath) as? MetricStatsCell {
            var metricsDataSource = [ChartData]()
            switch selectedMetricsPeriod {
            case .daily:
                metricsDataSource = metricsData.dailyData
            case .weekly:
                metricsDataSource = metricsData.weeklyData
            case .monthly:
                metricsDataSource = metricsData.monthlyData
            }
            cell.setUpCell(with: metricsDataSource[indexPath.row], hideSeparator: indexPath.row == metricsDataSource.count - 1)
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SystemUpdatesCell", for: indexPath) as? SystemUpdatesCell {
            cell.setUpCell(with: dataArray[indexPath.row], hideSeparator: indexPath.row == dataArray.count - 1)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let _ = dataSource[section].metricsData {
            return 1
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        if indexPath.row == 2 {
            let aboutScreen = AboutViewController()
            aboutScreen.details = appDetailsData
            navigationController?.pushViewController(aboutScreen, animated: true)
        } else {
            let reportScreen = HelpReportScreenViewController()
            reportScreen.delegate = self
            reportScreen.screenTitle = dataSource[indexPath.section].cellData[indexPath.row].app_title
            reportScreen.appSupportEmail = appDetailsData?.appSupportEmail
            presentPanModal(reportScreen)
        }
    }
    
}

extension ApplicationStatusViewController: MetricStatsHeaderDelegate {
    func periodWasChanged(_ header: MetricStatsHeader, to period: MetricsPeriod) {
        selectedMetricsPeriod = period
        let sectionIndexToReload = 2
        let indexPaths = tableView.visibleCells.compactMap { tableView.indexPath(for: $0) }.filter { $0.section == sectionIndexToReload
        }
        header.setChartData(selectedPeriod: period, data: dataSource[sectionIndexToReload].metricsData)
        tableView.reloadRows(at: indexPaths, with: .none)
    }
}

protocol ShowAlertDelegate: class {
    func showAlert(title: String?, message: String?)
}
