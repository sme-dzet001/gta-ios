//
//  HelpDeskCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 16.11.2020.
//

import UIKit

class HelpDeskCell: UITableViewCell {
    
    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellSubtitle: UILabel!
    @IBOutlet weak var updatesNumberLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: HelpDeskCellData) {
        if let imageName = data.imageName {
            cellIcon.image = UIImage(named: imageName)
        }
        cellTitle.text = data.cellTitle
        cellSubtitle.text = data.cellSubtitle
        if let updatesNumber = data.updatesNumber {
            updatesNumberLabel.text = "\(updatesNumber)"
        } else {
            updatesNumberLabel.text = nil
        }
    }
}
