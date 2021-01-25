//
//  HelpDeskContactOptionCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 30.11.2020.
//

import UIKit

class HelpDeskContactOptionCell: UITableViewCell {

    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellSubtitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: HelpDeskCellData, isActive: Bool = true) {
        if let imageName = data.imageName {
            cellIcon.image = UIImage(named: imageName)
        }
        cellTitle.text = data.cellTitle
        cellTitle.textColor = isActive ? .black : UIColor(hex: 0x8E8E93)
        cellSubtitle.text = data.cellSubtitle
    }
    
}
