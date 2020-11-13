//
//  AppsServiceAlertCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class AppsServiceAlertCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var separator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUpCell(with data: CellData, isNeedCornerRadius: Bool = false) {
        descriptionLabel.text = data.additionalText
        mainLabel.text = data.mainText
        if let image = data.image {
            iconImageView.image = UIImage(data: image)
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
    }
    
}
