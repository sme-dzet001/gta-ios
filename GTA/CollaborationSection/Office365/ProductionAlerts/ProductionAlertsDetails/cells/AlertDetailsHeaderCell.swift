//
//  AlertDetailsHeaderCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 21.04.2021.
//

import UIKit

class AlertDetailsHeaderCell: UITableViewCell {
    
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var alertNumberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    func setStatus(_ status: GlobalAlertStatus?) {
        switch status {
        case .inProgress, .open:
            statusLabel.text = status == .inProgress ? "In " : "Open"
            //separatorUnderStatusDate.isHidden = true
            statusLabel.textColor = UIColor(hex: 0x34C759)
        case .closed:
            statusLabel.text = "Closed"
            //separatorUnderStatusDate.isHidden = false
            statusLabel.textColor = UIColor(hex: 0xFF3E33)
        default: statusLabel.text = ""
        }
    }
    
}
