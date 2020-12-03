//
//  NewsCollectionViewCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 17.11.2020.
//

import UIKit

class NewsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: WebImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.set(imageURL: nil)
    }

}
