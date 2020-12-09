//
//  ApplicationCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class ApplicationCell: UITableViewCell {

    @IBOutlet weak var appIcon: UIImageView!
    @IBOutlet weak var appStatus: UIView!
    @IBOutlet weak var appName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: AppInfo) {
        if let image = data.imageData {
            appIcon.image = UIImage(data: image)
        }
        appName.text = data.app_title
        switch data.appStatus {
        case .online:
            appStatus.backgroundColor = UIColor(red: 52.0 / 255.0, green: 199.0 / 255.0, blue: 89.0 / 255.0, alpha: 1.0)
        case .offline:
            appStatus.backgroundColor = UIColor(red: 255.0 / 255.0, green: 62.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
        default:
            appStatus.backgroundColor = UIColor(red: 255.0 / 255.0, green: 153.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
        }
        appStatus.layer.cornerRadius = appStatus.frame.size.width / 2
    }
    
}
