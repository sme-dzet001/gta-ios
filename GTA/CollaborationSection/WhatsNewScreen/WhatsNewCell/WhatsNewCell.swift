//
//  WhatsNewCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit

class WhatsNewCell: UITableViewCell {
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        
    var imageUrl: String?
    var relativePath: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //setUpCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.mainImageView.clear()
//        mainImageView.gifImage = nil
//        mainImageView.image = nil
    }
     
    
//    func setUpCell() {
//        let font = UIFont(name: "SFProText-Light", size: 16)!
//        descriptionLabel.addReadMoreString("More")
//        //descriptionLabel.addTrailing(with: "On 10 September 2020, Jersey reclassified nine cases as old infections resulting in negative cases report dsdssd dsds sddsds vdfdffdkdfkjdfjkdf dkjfdjkfdjkfdkj dffddfkjdfkjdf", moreText: "More", moreTextFont: font, moreTextColor: .lightGray)
//    }
    
}
