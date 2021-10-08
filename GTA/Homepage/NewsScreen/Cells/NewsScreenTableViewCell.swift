//
//  NewsScreenTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit

class NewsScreenTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageStackView: UIStackView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setLineHeight(lineHeight: 10)
        subtitleLabel.setLineHeight(lineHeight: 10)
    }

    
    func setupCell(_ data: NewsData) {
        titleLabel.text = data.title
        subtitleLabel.text = data.text
        imageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let images = data.images {
            for image in images {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.image = image
                imageStackView.addArrangedSubview(imageView)
            }
        }
    }
    
}
