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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setAlertOn() {
        parentView.backgroundColor = UIColor(hex: 0xCC0000)
        alertImageView.image = UIImage(named: "global_alert_on")
    }
    
    func setAlertOff() {
        parentView.backgroundColor = UIColor(hex: 0x34C759)
        alertImageView.image = UIImage(named: "global_alert_off")
    }

    
}
