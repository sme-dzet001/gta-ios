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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //setUpCell()
    }
    
    func setUpCell(with data: CollaborationNewsRow?) {
        setImage(with: data?.imageData, status: data?.imageStatus ?? .loading)
        titleLabel.text = data?.headline
        subtitleLabel.text = data?.headline
        //descriptionLabel.text = data.title
    }
    
    func setImage(with data: Data?, status: LoadingStatus) {
        if status == .loading {
            startAnimation()
        } else {
            stopAnimation()
        }
        if let imageData = data, let image = UIImage(data: imageData) {
            mainImageView.image = image
        } else if status == .failed {
            mainImageView.image = nil
            //showFirstCharFrom(data.app_name)
        }
    }
    
    private func startAnimation() {
        mainImageView.isHidden = true
        self.activityIndicator.isHidden = false
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        mainImageView.isHidden = false
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
//    func setUpCell() {
//        let font = UIFont(name: "SFProText-Light", size: 16)!
//        descriptionLabel.addReadMoreString("More")
//        //descriptionLabel.addTrailing(with: "On 10 September 2020, Jersey reclassified nine cases as old infections resulting in negative cases report dsdssd dsds sddsds vdfdffdkdfkjdfjkdf dkjfdjkfdjkfdkj dffddfkjdfkjdf", moreText: "More", moreTextFont: font, moreTextColor: .lightGray)
//    }
    
}
