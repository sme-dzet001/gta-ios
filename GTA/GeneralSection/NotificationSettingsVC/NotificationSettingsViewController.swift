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
    
    private var isNotificationAuthorized: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        getNotificationPermision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(getNotificationPermision), name: UIApplication.willEnterForegroundNotification, object: nil)
        getCurrentPreferences()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func getCurrentPreferences() {
        dataProvider?.getCurrentPreferences(completion: {[weak self] code, error in
            if error == nil && code == 200 {
                DispatchQueue.main.async {
                    let isOn = (self?.dataProvider?.allowEmergencyOutageNotifications ?? true) && (self?.isNotificationAuthorized ?? true)
                    self?.delegate?.notificationStateUpdatedDelegate(state: isOn)
                }
            }
        })
    }
    
    @objc private func getNotificationPermision() {
        UNUserNotificationCenter.current().getNotificationSettings {[weak self] permisson in
            switch permisson.authorizationStatus {
            case .denied:
                self?.isNotificationAuthorized = false
                DispatchQueue.main.async {
                    self?.delegate?.notificationStateUpdatedDelegate(state: false)
                }
            default:
                self?.isNotificationAuthorized = true
            }
        }
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
        cell?.switchControl.isOn = isNotificationAuthorized ? Preferences.allowEmergencyOutageNotifications : false
        cell?.switchControl.switchStateChangedDelegate = self
        delegate = cell
        return cell ?? UITableViewCell()
    }
    
}

extension NotificationSettingsViewController: SwitchStateChangedDelegate {
    func notificationSwitchDidChanged(isOn: Bool, switchControl: Switch) {
        if isNotificationAuthorized {
            dataProvider?.setCurrentPreferences(nottificationsState: isOn, completion: {[weak self] code, error in
                if let err = error {
                    self?.displayError(errorMessage: err.localizedDescription, title: nil, onClose: nil)
                }
            })
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
    func notificationStateUpdatedDelegate(state: Bool)
}
