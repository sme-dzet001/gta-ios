//
//  ServiceDeskContactCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 04.12.2020.
//

import UIKit

class ServiceDeskContactCell: UITableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: ServiceDeskContact?) {
        if let imageName = data?.photoImageName {
            photoImageView.image = UIImage(named: imageName)
        }
        photoImageView.layer.cornerRadius = photoImageView.frame.size.width / 2
        contactNameLabel.text = data?.contactName
        positionLabel.text = data?.contactPosition
        descriptionLabel.text = data?.description
        emailLabel.text = data?.email
        locationLabel.text = data?.location
    }
    
}
