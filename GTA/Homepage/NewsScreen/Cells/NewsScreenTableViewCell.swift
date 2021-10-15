//
//  NewsScreenTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit
import Hero

protocol ImageViewDidTappedDelegate: AnyObject {
    func imageViewDidTapped(imageView: UIImageView)
}

class NewsScreenTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageStackView: UIStackView!
        
    weak var delegate: ImageViewDidTappedDelegate?
    
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
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
                let imageView = UIImageView()
                imageView.alpha = 1
                imageView.restorationIdentifier = image
                imageView.heroID = image
                imageView.addGestureRecognizer(tapGestureRecognizer)
                imageView.isUserInteractionEnabled = true
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: image)
                imageStackView.addArrangedSubview(imageView)
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        print("Tap")
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else { return }
        tappedImage.alpha = 0
        delegate?.imageViewDidTapped(imageView: tappedImage)
    }
    
}
