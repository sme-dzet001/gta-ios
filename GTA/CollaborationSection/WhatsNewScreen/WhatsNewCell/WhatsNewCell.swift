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
    var collapseText: NSAttributedString?
    weak var delegate: MoreTappedDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.descriptionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMoreDidTapped(gesture:)))
        tap.cancelsTouchesInView = false
        self.descriptionLabel.addGestureRecognizer(tap)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.stopAnimating()
        self.mainImageView.stopAnimatingGif()
        self.mainImageView.clear()
        //descriptionLabel.numberOfLines = 3
        self.layoutIfNeeded()
    }
    
    func setDate(_ date: String?) {
        if let date = date {
            subtitleLabel.text = date.getFormattedDateStringForMyTickets()
        } else {
            subtitleLabel.text = date
        }
    }
    
    @objc private func showMoreDidTapped(gesture: UITapGestureRecognizer) {
        delegate?.moreButtonDidTapped(in: self)
    }
    
    func setCollapseText() {
        descriptionLabel.numberOfLines = 3
        descriptionLabel.sizeToFit()
        self.layoutIfNeeded()
        descriptionLabel.attributedText = collapseText
        descriptionLabel.addReadMoreString("more")
        
       
    }
    
}
