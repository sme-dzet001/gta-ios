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
    
    var badgeNumber = 0 {
        didSet {
            let attributedString = NSMutableAttributedString(string: "\(badgeNumber)")
            attributedString.addAttribute(NSAttributedString.Key.kern, value: -0.2, range: NSRange(location: 0, length: attributedString.length))
            badgeLabel.attributedText = attributedString
            badgeLabel.isHidden = badgeNumber > 0 ? false : true
            badgeImageView.isHidden = !badgeLabel.isHidden
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeLabel.isHidden = true
        badgeLabel.backgroundColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
        badgeLabel.layer.masksToBounds = true
        badgeLabel.layer.borderWidth = 2
        badgeLabel.layer.borderColor = UIColor.white.cgColor
        
        badgeImageView.isHidden = true
        badgeImageView.layer.cornerRadius = badgeImageView.frame.height / 2
        badgeImageView.layer.borderWidth = 2
        badgeImageView.layer.borderColor = UIColor.white.cgColor
        badgeImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
