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
    var body: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.stopAnimating()
        self.mainImageView.stopAnimatingGif()
        self.mainImageView.clear()
        self.layoutIfNeeded()
    }
    
    func setDate(_ date: String?) {
        if let date = date {
            subtitleLabel.text = date.getFormattedDateStringForMyTickets()
        } else {
            subtitleLabel.text = date
        }
    }
    
}
