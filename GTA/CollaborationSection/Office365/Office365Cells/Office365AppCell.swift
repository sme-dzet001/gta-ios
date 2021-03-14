//
//  Office365AppCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.03.2021.
//

import UIKit

class Office365AppCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var iconImageViewWidth: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: CollaborationAppDetailsRow, isAppsScreen: Bool = false) {
        if isAppsScreen {
            iconImageViewWidth?.constant = 48
        }
        setImage(with: data.imageData, status: data.imageStatus)
        appTitleLabel.text = data.appNameFull
        descriptionLabel.text = data.title
    }
    
    func setImage(with data: Data?, status: ImageLoadingStatus) {
        if status == .loading {
            startAnimation()
        } else {
            stopAnimation()
        }
        if let imageData = data, let image = UIImage(data: imageData) {
            iconImageView.image = image
        } else if status == .failed {
            iconImageView.image = nil
            //showFirstCharFrom(data.app_name)
        }
    }
    
    private func startAnimation() {
        iconImageView.isHidden = true
        self.activityIndicator.isHidden = false
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        iconImageView.isHidden = false
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
}
