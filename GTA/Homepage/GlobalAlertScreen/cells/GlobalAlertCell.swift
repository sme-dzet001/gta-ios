//
//  GlobalAlertCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 14.05.2021.
//

import UIKit

class GlobalAlertCell: UITableViewCell {

    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    weak var delegate: DismissAlertDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setAlertOn() {
        parentView.backgroundColor = UIColor(hex: 0xCC0000)
        alertImageView.image = UIImage(named: "global_alert_on")
    }
    
    func setAlertOff() {
        alertLabel.text = (alertLabel.text ?? "") + ": fixed"
        parentView.backgroundColor = UIColor(hex: 0x34C759)
        alertImageView.image = UIImage(named: "global_alert_off")
    }
    
    @IBAction func closeButtonDidPressed(_ sender: Any) {
        delegate?.closeAlertDidPressed()
    }
    
    func setAlertBannerForGlobalProdAlert(startDate: Date, advancedTime: Double, status: GlobalAlertStatus) {
        if status == .inProgress {
            let advancedTimeInterval = 3600 * advancedTime
            if startDate.timeIntervalSince1970 - advancedTimeInterval < Date().timeIntervalSince1970 {
                parentView.backgroundColor = UIColor(hex: 0x34C759)
                alertImageView.image = UIImage(named: "global_alert_off")
                closeButton.isHidden = false
            } else if startDate.timeIntervalSince1970 - advancedTimeInterval >= Date().timeIntervalSince1970 {
                parentView.backgroundColor = UIColor(hex: 0x34C759)
                alertImageView.image = UIImage(named: "global_alert_off")
                closeButton.isHidden = false
            } else if startDate.timeIntervalSince1970 >= Date().timeIntervalSince1970 {
                closeButton.isHidden = true
                parentView.backgroundColor = UIColor(hex: 0xCC0000)
                alertImageView.image = UIImage(named: "global_alert_on")
            }
        } else if status == .closed {
            parentView.backgroundColor = UIColor(hex: 0x34C759)
            alertImageView.image = UIImage(named: "global_alert_off")
            closeButton.isHidden = true
        }
    }
    
}

protocol DismissAlertDelegate: AnyObject {
    func closeAlertDidPressed()
}
