//
//  GlobalAlertBannerView.swift
//  GTA
//
//  Created by Margarita N. Bock on 01.09.2021.
//

import UIKit

class GlobalAlertBannerView: UIView {
    
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    weak var delegate: DismissAlertDelegate?
    
    func setAlertOn() {
        parentView.backgroundColor = UIColor(hex: 0xCC0000)
        alertImageView.image = UIImage(named: "global_alert_on")
    }
    
    func setAlertOff() {
        parentView.backgroundColor = UIColor(hex: 0x34C759)
        alertImageView.image = UIImage(named: "global_alert_off")
    }
    
    @IBAction func closeButtonDidPressed(_ sender: Any) {
        delegate?.closeAlertDidPressed()
    }
    
    func setAlertBannerForGlobalProdAlert(prodAlertsStatus: ProductionAlertsStatus) {
        switch prodAlertsStatus {
        case .newAlertCreated, .reminderState:
            parentView.backgroundColor = UIColor(hex: 0xFF9900)
            alertImageView.image = UIImage(named: "global_alert_on")
            closeButton.isHidden = false
        case .activeAlert:
            closeButton.isHidden = true
            parentView.backgroundColor = UIColor(hex: 0xCC0000)
            alertImageView.image = UIImage(named: "global_alert_on")
        case .closed:
            parentView.backgroundColor = UIColor(hex: 0x34C759)
            alertImageView.image = UIImage(named: "global_alert_off")
            closeButton.isHidden = true
        default:
            return
        }
    }
    
}

protocol DismissAlertDelegate: AnyObject {
    func closeAlertDidPressed()
}
