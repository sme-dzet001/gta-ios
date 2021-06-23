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
    
    var dataSource: ProductionAlertsResponse?
    var appName: String?
    var selectedId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        if let id = selectedId {
            showAlertDetails(for: id)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        handleBlurShowing(animated: false)
    }
    
    private func setUpNavigationItem() {
        navigationController?.navigationBar.barTintColor = UIColor.white
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Production Alerts"
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
        tableView.register(UINib(nibName: "ProductionAlertCell", bundle: nil), forCellReuseIdentifier: "ProductionAlertCell")
    }
    
    func handleBlurShowing(animated: Bool) {
        let isReachedBottom = tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height).rounded(.towardZero)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = isReachedBottom ? 0 : 1
            }
        } else {
            blurView.alpha = isReachedBottom ? 0 : 1
        }
    }
    
    func addBlurToView() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
    private func showAlertDetails(for id: String) {
        let detailsVC = ProductionAlertsDetails()
        // for POC only
        // need to change in future
        if let index = dataProvider?.alertsData[appName ?? ""]??.data?.firstIndex(where: {$0?.id == id}) {
            dataProvider?.alertsData[appName ?? ""]??.data?[index]?.isRead = true
            detailsVC.alertData = dataProvider?.alertsData[appName ?? ""]??.data?[index]
        }
       // dataProvider?.alertsData[appName ?? ""]??.data?[row]?.isRead = true
        
        presentDetails(detailsVC: detailsVC)
    }
    
    private func showAlertDetails(for row: Int) {
        guard (dataSource?.data?.count ?? 0) > row else { return }
        let detailsVC = ProductionAlertsDetails()
        // for POC only
        // need to change in future
        dataProvider?.alertsData[appName ?? ""]??.data?[row]?.isRead = true
        detailsVC.alertData = dataProvider?.alertsData[appName ?? ""]??.data?[row]
        presentDetails(detailsVC: detailsVC)
    }
    
    private func presentDetails(detailsVC: ProductionAlertsDetails) {
        var totalCount = 0
        if let countArr = dataProvider?.alertsData.compactMap({$0.value?.data}) {
            for i in countArr {
                totalCount += i.filter({$0?.isRead == false}).count
            }
            let value = (Int(self.tabBarController?.tabBar.items?[2].badgeValue ?? "") ?? 0) - 1
            self.tabBarController?.tabBar.items?[2].badgeValue = value > 0 ? "\(value)" : nil
        }
        presentPanModal(detailsVC)
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension ProductionAlertsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.data?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductionAlertCell", for: indexPath) as? ProductionAlertCell
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAlertDetails(for: indexPath.row)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleBlurShowing(animated: true)
    }
    
}
