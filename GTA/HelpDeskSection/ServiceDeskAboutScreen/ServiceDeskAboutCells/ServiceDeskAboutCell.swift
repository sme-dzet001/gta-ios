//
//  ServiceDeskAboutCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 14.01.2021.
//

import UIKit

class ServiceDeskAboutCell: UITableViewCell {
    
    @IBOutlet weak var serviceDeskIcon: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
