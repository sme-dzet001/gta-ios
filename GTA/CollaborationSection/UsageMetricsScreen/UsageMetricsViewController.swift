//
//  UsageMetricsViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.04.2021.
//

import UIKit
import WebKit

class UsageMetricsViewController: UIViewController {
    
    private var dataProvider: UsageMetricsDataProvider = UsageMetricsDataProvider()
    
    deinit {
        activeUsersVC.removeFromParent()
    }
    
    private lazy var activeUsersVC: ActiveUsersViewController = {
        let activeUsersVC = ActiveUsersViewController()
        activeUsersVC.dataProvider = dataProvider
        return activeUsersVC
    }()
    
    private lazy var activeUsersChartCell: UITableViewCell = {
        let cell = UITableViewCell()
        activeUsersVC.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(activeUsersVC.view)
        NSLayoutConstraint.activate([
            activeUsersVC.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            activeUsersVC.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            activeUsersVC.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            activeUsersVC.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        addChild(activeUsersVC)
        return cell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.barTintColor = .white
        
        setUpNavigationItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Usage Metrics"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension UsageMetricsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return activeUsersChartCell
        default:
            return UITableViewCell()
        }
    }
    
    
}
