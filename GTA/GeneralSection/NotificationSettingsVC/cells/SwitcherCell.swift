//
//  SwitcherCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.05.2021.
//

import UIKit

class SwitcherCell: UITableViewCell {

    @IBOutlet weak var switchView: UIView!
    
    var switchControl = Switch()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        switchView.addSubview(switchControl)
        switchControl.topAnchor.constraint(equalTo: switchView.topAnchor).isActive = true
        switchControl.bottomAnchor.constraint(equalTo: switchView.bottomAnchor).isActive = true
        switchControl.leadingAnchor.constraint(equalTo: switchView.leadingAnchor).isActive = true
        switchControl.trailingAnchor.constraint(equalTo: switchView.trailingAnchor).isActive = true
    }
    
}

extension SwitcherCell: NotificationStateUpdatedDelegate {
    func notificationStateUpdatedDelegate(state: Bool) {
        switchControl.setOn(state, animated: true)
    }
}
