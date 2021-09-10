//
//  ProductionAlertCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.04.2021.
//

import UIKit

class ProductionAlertCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var alertNumberLabel: UILabel!
    @IBOutlet weak var descriptionLabelBottom: NSLayoutConstraint!
    @IBOutlet weak var dateLabelBottom: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setConstraints() {
        if descriptionLabel.frame.height >= 20 {
            dateLabelBottom?.isActive = false
            descriptionLabelBottom?.isActive = true
        } else {
            dateLabelBottom?.isActive = true
            descriptionLabelBottom?.isActive = false
        }
    }
}
