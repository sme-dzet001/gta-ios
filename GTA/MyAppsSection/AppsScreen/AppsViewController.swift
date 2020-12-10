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
    
    private var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        self.dataProvider.appImageDelegate = self
        getAppsData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }
    
    private func getAppsData() {
        startAnimation()
        dataProvider.getAppsCommonData {[weak self] (response, code, error) in
            if let responseData = response {
                self?.dataSource = []
                self?.setHardCodeData()
                self?.dataSource.append(contentsOf: responseData)
            }
            self?.stopAnimation()
            let appInfo = response?.map({$0.cellData}).reduce([], {$0 + $1})
            self?.dataProvider.getImageData(for: appInfo ?? [])
        }
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.center = CGPoint(x: view.frame.size.width  / 2,
                                                y: view.frame.size.height / 2)
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
        dataSource = [AppsDataSource(sectionName: nil, description: nil, cellData: [AppInfo(app_id: 0, app_name: "Service Alert: VPN Outage", app_title: "10:30 +5 GTM Wed 15", app_icon: nil, appStatus: .none, app_is_active: false, imageData: nil)])]
        
    }
    
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].cellData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
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
        appVC.appName = dataSource[indexPath.section].cellData[indexPath.row].app_title
        appVC.systemStatus = dataSource[indexPath.section].cellData[indexPath.row].appStatus
        self.navigationController?.pushViewController(appVC, animated: true)
    }

}

extension AppsViewController: AppImageDelegate {
    
    func setImage(with data: Data?, for appId: Int) {
        for (index, element) in dataSource.enumerated() {
            for (cellDataIndex, cellDataObject) in element.cellData.enumerated() {
                if cellDataObject.app_id == appId {
                    dataSource[index].cellData[cellDataIndex].imageData = data
                    dataSource[index].cellData[cellDataIndex].isImageDataEmpty = data == nil
                    reloadTableViewRow(for: IndexPath(row: cellDataIndex, section: index))
                }
            }
        }
    }
    
    private func reloadTableViewRow(for indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
}
