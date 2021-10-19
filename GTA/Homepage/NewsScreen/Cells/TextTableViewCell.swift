//
//  NewsScreenTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit
import Hero

protocol ImageViewDidTappedDelegate: AnyObject {
    func imageViewDidTapped(imageView: UIImageView)
}

class TextTableViewCell: UITableViewCell {
    
    @IBOutlet weak var newsTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        newsTextLabel.setLineHeight(lineHeight: 10)
    }
    
    func setupCell(text: String?) {
        let decodedText = formNewsBody(from: text)
        decodedText?.setFontFace(font: UIFont(name: "SFProText-Light", size: 16)!)
        newsTextLabel.attributedText = decodedText
    }
    
    private func formNewsBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
        guard let encodedText = base64EncodedText, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8), let htmlAttrString = htmlBodyString.htmlToAttributedString else { return nil }
        
        let res = NSMutableAttributedString(attributedString: htmlAttrString)
        res.trimCharactersInSet(.whitespacesAndNewlines)
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return res }
        
        let wholeRange = NSRange(res.string.startIndex..., in: res.string)
        let matches = (mailRegex.matches(in: res.string, options: [], range: wholeRange))
        for match in matches {
            guard let mailLinkRange = Range(match.range, in: res.string) else { continue }
            let mailLinkStr = res.string[mailLinkRange]
            if let linkUrl = URL(string: "mailto:\(mailLinkStr)") {
                res.addAttribute(.link, value: linkUrl, range: match.range)
            }
        }
        return res
    }
}
