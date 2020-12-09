//
//  SystemUpdatesCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 11.11.2020.
//

import UIKit

class SystemUpdatesCell: UITableViewCell {

    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var separator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: AppInfo, hideSeparator: Bool = false) {
        descriptionLabel.text = data.app_title
        mainTitleLabel.text = data.app_name
        separator.isHidden = hideSeparator
    }
    
}
