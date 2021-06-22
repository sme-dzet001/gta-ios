//
//  AlertDetailsHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 21.04.2021.
//

import UIKit

class AlertDetailsHeader: UIView {
    
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var alertNumberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    

    class func instanceFromNib() -> AlertDetailsHeader {
        let header = UINib(nibName: "AlertDetailsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! AlertDetailsHeader
        return header
    }

    func setStatus(_ status: TicketStatus?) {
        switch status {
        case .new, .open:
            statusLabel.text = status == .new ? "New" : "Open"
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
