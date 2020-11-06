//
//  AppsServiceAlertCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class AppsServiceAlertCell: UITableViewCell {
    
    @IBOutlet weak var alertTimeLabel: UILabel!
    @IBOutlet weak var alertMainLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: CellData) {
        alertTimeLabel.text = data.additionalText
        alertMainLabel.text = data.mainText
       
    }
    
}
