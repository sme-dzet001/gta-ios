//
//  SwitcherCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class SwitcherCell: UITableViewCell {

    @IBOutlet weak var notificationSwitch: UISwitch!
    
    weak var switchStateChangedDelegate: SwitchStateChangedDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func notificationSwitchDidChanged(_ sender: UISwitch) {
        switchStateChangedDelegate?.notificationSwitchDidChanged(isOn: sender.isOn)
    }
    
}

extension SwitcherCell: NotificationStateUpdatedDelegate {
    func notificationStateUpdatedDelegate(state: Bool) {
        notificationSwitch.isOn = state
    }
}

protocol SwitchStateChangedDelegate: AnyObject {
    func notificationSwitchDidChanged(isOn: Bool)
}
