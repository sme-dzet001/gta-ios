//
//  NotificationSettingsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class NotificationSettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: GeneralDataProvider?
    weak var delegate: NotificationStateUpdatedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataProvider?.getCurrentPreferences(completion: {[weak self] code, error in
            if error == nil && code == 200 {
                DispatchQueue.main.async {
                    self?.delegate?.notificationStateUpdatedDelegate(state: self?.dataProvider?.allowEmergencyOutageNotifications ?? true)
                }
            }
        })
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
        cell?.notificationSwitch.isOn = Preferences.allowEmergencyOutageNotifications
        cell?.switchStateChangedDelegate = self
        delegate = cell
        return cell ?? UITableViewCell()
    }
    
}

extension NotificationSettingsViewController: SwitchStateChangedDelegate {
    func notificationSwitchDidChanged(isOn: Bool) {
        dataProvider?.setCurrentPreferences(nottificationsState: isOn)
    }
}

protocol NotificationStateUpdatedDelegate: AnyObject {
    func notificationStateUpdatedDelegate(state: Bool)
}
