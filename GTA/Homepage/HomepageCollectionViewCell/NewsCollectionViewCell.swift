//
//  NewsCollectionViewCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 17.11.2020.
//

import UIKit

class NewsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var defaultTitleLabelY: NSLayoutConstraint!
    @IBOutlet weak var titleLabelYForSmallScreen: NSLayoutConstraint!
    
    var imageUrl: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.iPhone5_se {
            defaultTitleLabelY.isActive = false
            titleLabelYForSmallScreen.isActive = true
        }
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

}
