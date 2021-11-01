//
//  SwitcherCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class SwitcherCell: UITableViewCell {

    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var switchControl = Switch()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        switchView.addSubview(switchControl)
        switchControl.topAnchor.constraint(equalTo: switchView.topAnchor).isActive = true
        switchControl.bottomAnchor.constraint(equalTo: switchView.bottomAnchor).isActive = true
        switchControl.leadingAnchor.constraint(equalTo: switchView.leadingAnchor).isActive = true
        switchControl.trailingAnchor.constraint(equalTo: switchView.trailingAnchor).isActive = true
        
        setAccessibilityIdentifiers()
    }
    
    private func setAccessibilityIdentifiers() {
        label.accessibilityIdentifier = "SwitcherCellLabel"
        switchControl.accessibilityIdentifier = "SwitcherCellSwitchControl"
    }
    
}

extension SwitcherCell: NotificationStateUpdatedDelegate {
    func notificationStateUpdatedDelegate(isNotificationAuthorized: Bool) {
        guard isNotificationAuthorized else { return }
        switch switchControl.switchNotificationsType {
        case .emergencyOutageNotifications:
            switchControl.setOn(Preferences.allowEmergencyOutageNotifications, animated: true)
        default:
            switchControl.setOn(Preferences.allowProductionAlertsNotifications, animated: true)
        }
//        if switchControl.switchNotificationsType == type {
//            switchControl.setOn(state, animated: true)
//        }
    }
}
