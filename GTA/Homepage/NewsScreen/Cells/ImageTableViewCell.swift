//
//  ImageTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 18.10.2021.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var newsImageView: UIImageView!
    
    weak var delegate: ImageViewDidTappedDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupCell() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        let imageView = UIImageView()
        newsImageView.alpha = 1
        //newsImageView.restorationIdentifier = image
        //newsImageView.heroID = image
        newsImageView.addGestureRecognizer(tapGestureRecognizer)
        newsImageView.isUserInteractionEnabled = true
        newsImageView.contentMode = .scaleAspectFit
        //newsImageView.image = UIImage(named: image)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        print("Tap")
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else { return }
        tappedImage.alpha = 0
        delegate?.imageViewDidTapped(imageView: tappedImage)
    }
    
}
