//
//  AboutInfoCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutInfoCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with description: String?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let attrString = NSMutableAttributedString(string: description ?? "")
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
        if let textFont = UIFont(name: "SFProDisplay-Light", size: 16.0) {
            attrString.addAttribute(.font, value: textFont, range: NSMakeRange(0, attrString.length))
        }

        descriptionLabel.attributedText = attrString
    }
    
}
