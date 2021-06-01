//
//  GlobalAlertDetailsHeaderCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.05.2021.
//

import UIKit

class GlobalAlertDetailsHeaderCell: UITableViewCell {
    
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var alertNumberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    func setStatus(_ status: GlobalAlertStatus?) {
        switch status {
        case .inProgress, .open:
            statusLabel.text = status == .inProgress ? "In Progress" : "Open"
            //separatorUnderStatusDate.isHidden = true
            statusLabel.textColor = UIColor(hex: 0xFF3E33)
        case .closed:
            statusLabel.text = "Closed"
            //separatorUnderStatusDate.isHidden = false
            statusLabel.textColor = UIColor(hex: 0x34C759)
        default: statusLabel.text = ""
        }
    }
    
}
