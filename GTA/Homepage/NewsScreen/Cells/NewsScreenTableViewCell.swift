//
//  NewsScreenTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit

class NewsScreenTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setLineHeight(lineHeight: 10)
        subtitleLabel.setLineHeight(lineHeight: 10)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
