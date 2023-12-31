//
//  NotificationSettingsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class NotificationSettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSeparator: UIView!
    
    var dataProvider: GeneralDataProvider?
    weak var delegate: NotificationStateUpdatedDelegate?
    
    private var isNotificationAuthorized: Bool = false
    private var isEmergencySwitchOn: Bool {
        return Preferences.allowEmergencyOutageNotifications && isNotificationAuthorized
    }
    
    private var isProductionAlertSwitchOn: Bool {
        return Preferences.allowProductionAlertsNotifications && isNotificationAuthorized
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        NotificationCenter.default.addObserver(self, selector: #selector(getNotificationsData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        getNotificationsData()
    }
    
    private func getCurrentPreferences() {
        dataProvider?.getCurrentPreferences(completion: {[weak self] code, error in
            if error == nil && code == 200 {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        })
    }
    
    @objc private func getNotificationPermision() {
        UNUserNotificationCenter.current().getNotificationSettings {[weak self] permisson in
            switch permisson.authorizationStatus {
            case .denied:
                self?.isNotificationAuthorized = false
            default:
                self?.isNotificationAuthorized = true
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func getNotificationsData() {
        getNotificationPermision()
        getCurrentPreferences()
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
        navigationItem.titleView?.accessibilityIdentifier = "NotificationSettingsViewControllerTitleView"
        if #available(iOS 15.0, *) {
            headerSeparator.isHidden = false
        }
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
}

extension NotificationSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitcherCell", for: indexPath) as? SwitcherCell
        switch indexPath.row {
        case 0:
            cell?.label.text = "Emergency Outage Notifications"
            cell?.switchControl.setOn(isEmergencySwitchOn, animated: true)//isOn = isEmergencySwitchOn
            cell?.switchControl.switchNotificationsType = .emergencyOutageNotifications
        default:
            cell?.label.text = "Production Alerts Notifications"
            cell?.switchControl.setOn(isProductionAlertSwitchOn, animated: true) //isOn = isProductionAlertSwitchOn
            cell?.switchControl.switchNotificationsType = .productionAlertsNotifications
        }
        cell?.switchControl.switchStateChangedDelegate = self
        delegate = cell
        return cell ?? UITableViewCell()
    }
    
}

extension NotificationSettingsViewController: SwitchStateChangedDelegate {
    func notificationSwitchDidChanged(isOn: Bool, switchControl: Switch) {
        if isNotificationAuthorized {
            if Reachability.isConnectedToNetwork() {
                let notificationsType = switchControl.switchNotificationsType ?? .emergencyOutageNotifications
                dataProvider?.setCurrentPreferences(notificationsState: isOn, notificationsType: notificationsType, completion: {[weak self] code, error in
                    if error != nil {
                        DispatchQueue.main.async {
                            self?.displayError(errorMessage: "Notification Settings failed", title: nil, onClose: nil)
                            switchControl.setOn(!isOn, animated: true)
                        }
                    }
                })
            } else {
                displayError(errorMessage: "Notification Settings failed", title: nil, onClose: nil)
                switchControl.setOn(!isOn, animated: true)
            }
        } else {
            switchControl.setOn(false, animated: true)
            showNotificationNeededAlert()
        }
    }
    
    private func showNotificationNeededAlert() {
        let alert = UIAlertController(title: nil, message: "Enable Notifications setting to receive push notifications", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

protocol NotificationStateUpdatedDelegate: AnyObject {
    func notificationStateUpdatedDelegate(isNotificationAuthorized: Bool)
}
