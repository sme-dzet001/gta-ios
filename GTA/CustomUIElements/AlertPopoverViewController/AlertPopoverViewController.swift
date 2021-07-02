//
//  AlertPopoverViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 23.04.2021.
//

import UIKit

class AlertPopoverViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var alertsData: [ProductionAlertsRow?]?
    var appName: String = ""
    weak var delegate: AlertPopoverSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let count = (alertsData?.count ?? 0) > 2 ? (alertsData?.count ?? 0) - 2 : 0
        alertsData = Array(alertsData?.dropFirst(count) ?? [])
        setUpTableView()
        self.tableView.sizeToFit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.layoutIfNeeded()
        if (alertsData?.count ?? 0) > 1 {
            self.preferredContentSize = self.tableView.contentSize
        } else {
            var contentSize = self.tableView.contentSize
            contentSize.height = self.tableView.contentSize.height + 10
            topConstraint?.constant = 5
            self.preferredContentSize = contentSize
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AlertPopoverCell", bundle: nil), forCellReuseIdentifier: "AlertPopoverCell")
    }

}

extension AlertPopoverViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alertsData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let count = alertsData?.count, count > indexPath.row, let data = alertsData?[indexPath.row] else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlertPopoverCell", for: indexPath) as? AlertPopoverCell
        cell?.ticketNumberLabel.text = data.ticketNumber
        cell?.descriptionLabel.text = data.description
        cell?.separator.isHidden = indexPath.row == count - 1
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (alertsData?.count ?? 0) > indexPath.row else { return }
        self.dismiss(animated: false, completion: nil)
        delegate?.didSelectAlertId(alertsData?[indexPath.row]?.ticketNumber, appName: appName)
    }
    
}

protocol AlertPopoverSelectionDelegate: AnyObject {
    func didSelectAlertId(_ id: String?, appName: String)
}
