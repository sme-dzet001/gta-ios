//
//  AboutSupportCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 21.12.2020.
//

import UIKit

class AboutSupportCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with attributedString: NSMutableAttributedString?) {
        if let _ = attributedString, let textFont = UIFont(name: "SFProDisplay-Light", size: 16.0) {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            paragraphStyle.paragraphSpacing = 10
            attributedString!.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString!.length))
            attributedString!.addAttribute(.font, value: textFont, range: NSMakeRange(0, attributedString!.length))
            attributedString!.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, attributedString!.length))
            textView.attributedText = attributedString
            textView.linkTextAttributes = [.foregroundColor: UIColor.black, .underlineStyle: NSUnderlineStyle.single.rawValue]
        }
    }
    
}
