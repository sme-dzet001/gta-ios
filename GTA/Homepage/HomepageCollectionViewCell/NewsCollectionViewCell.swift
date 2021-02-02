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
    @IBOutlet weak var byLineHeight: NSLayoutConstraint?
    
    var imageUrl: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.iPhone5_se {
            defaultTitleLabelY.isActive = false
            titleLabelYForSmallScreen.isActive = true
        }
        // Initialization code
    }
    
    func configurePosition() {
        let constraint = UIDevice.current.iPhone5_se ? titleLabelYForSmallScreen : defaultTitleLabelY
        var multiplier: CGFloat = 1.0
        var newConstraint: NSLayoutConstraint?
        if let byLine = byLabel.text, !byLine.isEmpty {
            byLineHeight?.isActive = true
        } else {
            byLineHeight?.isActive = false
            multiplier = UIDevice.current.iPhone5_se ? 1.2 : 1.4
            newConstraint = constraint!.constraintWithMultiplier(multiplier)
            self.contentView.removeConstraint(constraint!)
            self.contentView.addConstraint(newConstraint!)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

}
