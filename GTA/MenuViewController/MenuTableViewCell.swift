//
//  MenuTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.09.2021.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var menuImage: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeLabel.backgroundColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
        badgeLabel.layer.masksToBounds = true
        badgeLabel.layer.borderWidth = 2
        badgeLabel.layer.borderColor = UIColor.white.cgColor
        
        badgeImageView.layer.cornerRadius = badgeImageView.frame.height / 2
        badgeImageView.layer.borderWidth = 2
        badgeImageView.layer.borderColor = UIColor.white.cgColor
        badgeImageView.layer.masksToBounds = true
        
        setAccessibilityIdentifiers()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    private func setAccessibilityIdentifiers() {
        menuLabel.accessibilityIdentifier = "MenuTableViewCellMenuLabel"
    }
    
    func setupCell(text: String, image: UIImage?, globalAlertsBadge: Int, productionAlertBadge: Int, indexPath: IndexPath) {
        menuLabel.textColor = .black
        menuImage.tintColor = .black
        badgeImageView.isHidden = true
        badgeLabel.isHidden = true
        
        menuLabel.text = text
        menuImage.image = image
        
        if indexPath.row == 0, globalAlertsBadge > 0 {
            badgeImageView.isHidden = false
            badgeImageView.image = UIImage(named: "global_alert_badge")
        }
        
        if indexPath.row == 2, productionAlertBadge > 0 {
            let attributedString = NSMutableAttributedString(string: "\(productionAlertBadge)")
            attributedString.addAttribute(NSAttributedString.Key.kern, value: -0.2, range: NSRange(location: 0, length: attributedString.length))
            badgeLabel.isHidden = false
            badgeLabel.attributedText = attributedString
        }
    }
    
    func selectCell(color: UIColor) {
        menuLabel.textColor = color
        menuImage.tintColor = color
    }
    
}
