//
//  UsageMetricsViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.04.2021.
//

import UIKit
import WebKit

protocol ChartDimensions: AnyObject {
    var optimalHeight: CGFloat { get }
}

class ChartTableView : UITableView, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class UsageMetricsViewController: UIViewController {
    
    @IBOutlet weak var tableView: ChartTableView!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    var dataProvider: CollaborationDataProvider?
    
    deinit {
        activeUsersVC.removeFromParent()
        teamChatUsersVC.removeFromParent()
        teamsByFunctionsVC.removeFromParent()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private lazy var activeUsersVC: ActiveUsersViewController = {
        let activeUsersVC = ActiveUsersViewController(nibName: "ActiveUsersViewController", bundle: nil)
        activeUsersVC.chartData = dataProvider?.activeUsersLineChartData
        return activeUsersVC
    }()
    
    private lazy var teamsByFunctionsVC: TeamsByFunctionsViewController = {
        let teamsByFunctionsVC = TeamsByFunctionsViewController(nibName: "TeamsByFunctionsViewController", bundle: nil)
        teamsByFunctionsVC.data = dataProvider?.teamsByFunctionsLineChartData
        return teamsByFunctionsVC
    }()
    
    private lazy var teamChatUsersVC: TeamChatUsersViewController = {
        let teamChatUsersVC = TeamChatUsersViewController()
        teamChatUsersVC.chartData = dataProvider?.horizontalChartData
        return teamChatUsersVC
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
    
    private lazy var teamsByFunctionsChartCell: UITableViewCell = {
        let cell = UITableViewCell()
        teamsByFunctionsVC.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(teamsByFunctionsVC.view)
        NSLayoutConstraint.activate([
            teamsByFunctionsVC.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            teamsByFunctionsVC.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            teamsByFunctionsVC.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            teamsByFunctionsVC.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        addChild(teamsByFunctionsVC)
        return cell
    }()
    
    private lazy var teamChatUsersChartCell: UITableViewCell = {
        let cell = UITableViewCell()
        teamChatUsersVC.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(teamChatUsersVC.view)
        NSLayoutConstraint.activate([
            teamChatUsersVC.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            teamChatUsersVC.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            teamChatUsersVC.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            teamChatUsersVC.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        addChild(teamChatUsersVC)
        return cell
    }()
    
    private lazy var activeUsersByFuncChartCell: UITableViewCell = {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BarChartCell") as? BarChartCell else { return UITableViewCell() }
        cell.setUpBarChartView(with: dataProvider?.verticalChartData)
        return cell
    }()
    
    private var chartCells: [UITableViewCell] = []
    
    private var chartDimensionsDict: [Int : ChartDimensions] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(getChartsData), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.barTintColor = .white
        
        tableView.register(UINib(nibName: "BarChartCell", bundle: nil), forCellReuseIdentifier: "BarChartCell")
        
        setUpNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        getChartsData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func getChartsData() {
        startAnimation()
        dataProvider?.getUsageMetrics {[weak self] isFromCache, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.stopAnimation()
                    self?.reloadData()
                } else if error != nil, !isFromCache {
                    self?.stopAnimation(with: error)
                }
            }
        }
    }
    
    private func reloadData() {
        chartDimensionsDict[0] = activeUsersVC
        if let barChartCell = activeUsersByFuncChartCell as? BarChartCell {
            chartDimensionsDict[1] = barChartCell
        }
        chartDimensionsDict[2] = teamChatUsersVC
        chartDimensionsDict[3] = teamsByFunctionsVC
        self.chartCells = [activeUsersChartCell, activeUsersByFuncChartCell, teamChatUsersChartCell, teamsByFunctionsChartCell]
        self.tableView.reloadData()
    }
    
    private func startAnimation() {
        self.errorLabel.isHidden = true
        self.tableView.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation(with error: Error? = nil) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.errorLabel.isHidden = error == nil
            self.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
            self.tableView.alpha = error == nil ? 1 : 0
           // self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
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
        return chartCells.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let chartDimensions = chartDimensionsDict[indexPath.row] {
            return chartDimensions.optimalHeight
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < chartCells.count else { return UITableViewCell() }
        return chartCells[indexPath.row]
    }
    
    
}
