//
//  HelpDeskHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 30.11.2020.
//

import UIKit

class HelpDeskHeader: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hoursOfOperationLabel: UILabel!
    @IBOutlet weak var separatorHeight: NSLayoutConstraint!
    
    class func instanceFromNib() -> HelpDeskHeader {
        let header = UINib(nibName: "HelpDeskHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! HelpDeskHeader
        return header
    }
    
    func setStatus(statusData: HelpDeskStatus) {
        switch statusData.status {
        case .online, .none, .expired:
            statusView.backgroundColor = UIColor(hex: 0x34C759)
            statusLabel.text = "Avg wait time is under 1 minute"
        case .offline:
            statusView.backgroundColor = UIColor(hex: 0xFF3E33)
            statusLabel.text = "An outage exists"
        case .pendingAlerts:
            statusView.backgroundColor = UIColor(hex: 0xFF9900)
            statusLabel.text = "Wait times may be slightly longer than usual"
        }
        hoursOfOperationLabel.text = statusData.hoursOfOperation
        statusView.isHidden = statusData.status == .none
        statusLabel.isHidden = statusData.status == .none
        hoursOfOperationLabel.isHidden = statusData.hoursOfOperation == nil
    }

}
