//
//  DeviceCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 17.11.2020.
//

import UIKit

protocol DeviceCellDelegate: class {
    func deviceCellSwitchStateWasChanged(_ cell: DeviceCell, to active: Bool)
}

class DeviceCell: UITableViewCell {
    
    @IBOutlet weak var deviceIcon: UIImageView!
    @IBOutlet weak var deviceTitleLabel: UILabel!
    @IBOutlet weak var isActiveSwitch: UISwitch!
    @IBOutlet weak var deviceTypeLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceNumberLabel: UILabel!
    @IBOutlet weak var deviceSerialNumberLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    weak var delegate: DeviceCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: DeviceData, hideSeparator: Bool = false) {
        switch data.deviceType {
        case .phone:
            deviceIcon.image = UIImage(named: "iPhone_icon")
        case .tablet:
            deviceIcon.image = UIImage(named: "iPad_icon")
        }
        isActiveSwitch.isOn = data.isActive ?? false
        deviceTitleLabel.text = data.deviceTitle
        deviceTypeLabel.text = data.deviceModel
        deviceNameLabel.text = data.deviceName
        deviceNumberLabel.text = data.deviceNumber
        deviceSerialNumberLabel.text = data.serialNumber
        separatorView.isHidden = hideSeparator
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        delegate?.deviceCellSwitchStateWasChanged(self, to: sender.isOn)
    }
}
