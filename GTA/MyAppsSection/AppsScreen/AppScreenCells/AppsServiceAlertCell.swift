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
    @IBOutlet weak var stackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUpCell(with data: AppInfo, isNeedCornerRadius: Bool = false, isDisabled: Bool = false, index: Int, error: Error? = nil) {
        var spacing: CGFloat = 8
        descriptionLabel.text = data.app_name
        mainLabel.text = data.app_title
        mainLabel.textColor = isDisabled ? UIColor(hex: 0x8E8E93) : .black
        if let _ = data.imageData {
            iconImageView.image = UIImage(data: data.imageData!)
        }
        if isNeedCornerRadius {
            self.parentView.layer.cornerRadius = 20
            self.parentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        if isDisabled {
            descriptionLabel.text = index < 2 ? "No email" : nil
            spacing = index < 2 ? 8 : 0
        }
        if let downloadError = error as? ResponseError, isDisabled {
            descriptionLabel.text = downloadError.localizedDescription
        }
        stackView.spacing = spacing
    }
    
    func setMainLabelAtCenter() {
        stackView.spacing = 0
        descriptionLabel.text = nil
    }
    
}
