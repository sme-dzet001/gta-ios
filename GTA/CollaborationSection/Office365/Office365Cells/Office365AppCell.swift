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
    @IBOutlet weak var iconLabel: UILabel!
    
    var imageUrl: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        activityIndicator.stopAnimating()
    }
    
    func setUpCell(with data: CollaborationAppDetailsRow, isAppsScreen: Bool = false) {
        if isAppsScreen {
            iconImageViewWidth?.constant = 24
        }
        //setImage(with: data.imageData, status: data.imageStatus)
        appTitleLabel.text = data.fullTitle
        descriptionLabel.text = data.title
    }
    
    func showFirstChar() {
        iconImageView.isHidden = false
        iconImageView.image = UIImage(named: "empty_app_icon")
        guard let char = appTitleLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return }
        iconLabel.text = char.uppercased()
        iconLabel.isHidden = false
    }
    
//    func setImage(with data: Data?, status: LoadingStatus) {
//        if status == .loading {
//            startAnimation()
//        } else {
//            stopAnimation()
//        }
//        if let imageData = data, let image = UIImage(data: imageData) {
//            iconImageView.image = image
//        } else if status == .failed {
//            iconImageView.image = nil
//            //showFirstCharFrom(data.app_name)
//        }
//    }
//
//    private func startAnimation() {
//        iconImageView.isHidden = true
//        self.activityIndicator.isHidden = false
//        self.activityIndicator.hidesWhenStopped = true
//        self.activityIndicator.startAnimating()
//    }
//
//    private func stopAnimation() {
//        iconImageView.isHidden = false
//        self.activityIndicator.isHidden = true
//        self.activityIndicator.stopAnimating()
//    }
    
}
