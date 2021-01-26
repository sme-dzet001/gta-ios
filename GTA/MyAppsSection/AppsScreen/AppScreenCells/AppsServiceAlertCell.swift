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
    @IBOutlet weak var topSeparator: UILabel!
    @IBOutlet weak var arrowIcon: UIImageView!
    @IBOutlet weak var mainLabelCenterY: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUpCell(with data: AppInfo, isNeedCornerRadius: Bool = false, isDisabled: Bool = false, error: Error? = nil) {
        descriptionLabel.text = data.app_name
        mainLabel.text = data.app_title
        if let imageData = data.appImageData.imageData, let image = UIImage(data: imageData) {
            iconImageView.image = image
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        if isDisabled {
            mainLabel.textColor = UIColor(hex: 0x8E8E93)
        } else {
            mainLabel.textColor = .black
        }
        if let downloadError = error as? ResponseError, isDisabled {
            descriptionLabel.text = downloadError.localizedDescription
        }
    }
    
    func setMainLabelAtCenter() {
        let newConstraint = mainLabelCenterY.constraintWithMultiplier(1.0)
        contentView.removeConstraint(mainLabelCenterY)
        contentView.addConstraint(newConstraint)
    }
    
}
