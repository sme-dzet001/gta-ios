//
//  NotificationSettingsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class NotificationSettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
    }

    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "SwitcherCell", bundle: nil), forCellReuseIdentifier: "SwitcherCell")
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Notification Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.tintColor = .black
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension NotificationSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitcherCell", for: indexPath) as? SwitcherCell
        return cell ?? UITableViewCell()
    }
    
}
