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
    
    var imageUrl: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }

    func setUpCell(with data: TeamContactsRow?) {
        photoImageView.layer.cornerRadius = photoImageView.frame.size.width / 2
        contactNameLabel.text = data?.contactName
        positionLabel.text = "Administrator"
        descriptionLabel.text = data?.contactBio
        emailLabel.text = data?.contactEmail
        locationLabel.text = "US - New York"
    }
    
}
