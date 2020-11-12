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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: CellData) {
        descriptionLabel.text = data.additionalText
        mainTitleLabel.text = data.mainText
    }
    
}
