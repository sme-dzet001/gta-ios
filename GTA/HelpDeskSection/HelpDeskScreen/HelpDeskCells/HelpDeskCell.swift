//
//  HelpDeskCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 16.11.2020.
//

import UIKit

class HelpDeskCell: UITableViewCell {
    
    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellSubtitle: UILabel!
    @IBOutlet weak var updatesNumberLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var titleBottom: NSLayoutConstraint!
    @IBOutlet weak var titleCenterY: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: ContactsCellDataProtocol, isActive: Bool = true, isNeedCornerRadius: Bool = false) {
        if let imageName = data.imageName {
            cellIcon.image = UIImage(named: imageName)
        }
        cellTitle.text = data.cellTitle
        cellTitle.textColor = isActive ? .black : UIColor(hex: 0x8E8E93)
        cellSubtitle.text = data.cellSubtitle
        if let updatesNumber = data.updatesNumber {
            updatesNumberLabel.text = "\(updatesNumber)"
        } else {
            updatesNumberLabel.text = nil
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        titleCenterY?.isActive = false
        titleBottom?.isActive = true
       
    }
    
    func setTitleAtCenter() {
        titleBottom?.isActive = false
        titleCenterY?.isActive = true
        cellSubtitle?.text = nil
    }
    
}

extension HelpDeskCell: TicketsNumberDelegate {
    func ticketNumberUpdated(_ number: Int?) {
        if let updatesNumber = number {
            updatesNumberLabel.text = "\(updatesNumber)"
        } else {
            updatesNumberLabel.text = nil
        }
    }
}
