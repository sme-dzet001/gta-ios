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
            guard badgeNumber > 0  else { return badgeLabel.isHidden = true }
            badgeLabel.isHidden = badgeNumber > 0 ? false : true
            badgeLabel.text = "\(badgeNumber)"
            badgeImageView.isHidden = !badgeLabel.isHidden
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeLabel.isHidden = true
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
        badgeLabel.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
