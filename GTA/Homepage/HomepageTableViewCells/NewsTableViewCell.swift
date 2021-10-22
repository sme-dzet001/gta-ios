//
//  NewsTableViewCell.swift
//  GTA
//
//  Created by Margarita N. Bock on 01.09.2021.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    var fullText: NSAttributedString?
    weak var delegate: TappedLabelDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bodyLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMoreDidTapped(gesture:)))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
    }
    
    @objc private func showMoreDidTapped(gesture: UITapGestureRecognizer) {
        delegate?.moreButtonDidTapped(in: self)
    }

    func setCollapse() {
        bodyLabel.numberOfLines = 3
        bodyLabel.sizeToFit()
        self.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.bodyLabel.attributedText = self?.fullText
            self?.bodyLabel.addReadMoreString("")
        }
    }
    
}
