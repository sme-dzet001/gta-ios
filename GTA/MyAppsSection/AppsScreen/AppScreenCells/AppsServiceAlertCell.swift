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
    @IBOutlet weak var iconWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUpCell(with data: AppInfo, isNeedCornerRadius: Bool = false, isDisabled: Bool = false, error: Error? = nil) {
        descriptionLabel.text = data.app_name
        mainLabel.text = data.app_title
        if let image = data.imageData {
            iconImageView.image = UIImage(data: image)
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        if isDisabled {
            self.parentView.backgroundColor = UIColor(red: 142.0 / 255.0, green: 142.0 / 255.0, blue: 147.0 / 255.0, alpha: 0.3)
        } else {
            self.parentView.backgroundColor = .white
        }
        if let downloadError = error as? ResponseError, isDisabled {
            descriptionLabel.text = downloadError.localizedDescription
        }
    }
    
}
