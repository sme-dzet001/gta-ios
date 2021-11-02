//
//  CollaborationCounterCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 08.04.2021.
//

import UIKit

class CollaborationCounterCell: UITableViewCell {
        
    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellSubtitle: UILabel!
    @IBOutlet weak var updatesNumberLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setAccessibilityIdentifiers()
    }
    
    func setUpCell(with data: ContactsCellDataProtocol, isActive: Bool = true, isNeedCornerRadius: Bool = false) {
        if let imageName = data.imageName {
            cellIcon.image = UIImage(named: imageName)
        }
        cellTitle.text = data.cellTitle
        cellTitle.textColor = isActive ? .black : UIColor(hex: 0x8E8E93)
        cellSubtitle.text = data.cellSubtitle
        if let updatesNumber = data.updatesNumber {
            updatesNumberLabel.isHidden = false
            updatesNumberLabel.text = "\(updatesNumber)"
        } else {
            updatesNumberLabel.isHidden = true
            updatesNumberLabel.text = nil
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
    }
    
    private func setAccessibilityIdentifiers() {
        updatesNumberLabel.accessibilityIdentifier = "CollaborationCounterCellUpdatesNumberLabel"
    }
    
}

extension CollaborationCounterCell: TicketsNumberDelegate {
    func ticketNumberUpdated(_ number: Int?) {
        if let updatesNumber = number {
            updatesNumberLabel.text = "\(updatesNumber)"
            updatesNumberLabel.isHidden = false
        } else {
            updatesNumberLabel.isHidden = true
            updatesNumberLabel.text = nil
        }
    }
}

