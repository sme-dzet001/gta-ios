//
//  AboutHeaderCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 14.01.2021.
//

import UIKit

class AboutHeaderCell: UITableViewCell {

    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func showFirstCharFrom(_ text: String?) {
        self.imageView?.isHidden = false
        guard let char = text?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return }
        iconLabel.text = char.uppercased()
        iconLabel.isHidden = false
    }
    
    func startAnimation() {
        self.imageView?.isHidden = true
        activityIndicator.startAnimating()
    }
    
    func stopAnimation() {
        self.imageView?.isHidden = false
        activityIndicator.stopAnimating()
    }
    
}
