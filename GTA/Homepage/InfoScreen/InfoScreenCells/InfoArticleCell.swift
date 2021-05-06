//
//  InfoArticleCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit

class InfoArticleCell: UITableViewCell {

    @IBOutlet weak var infoLabel: UILabel!
    
    weak var delegate: OpenLinkDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.infoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tryOpenLink(gesture:))))
    }
    
    @objc private func tryOpenLink(gesture: UITapGestureRecognizer) {
        guard let text = infoLabel.attributedText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var isFindURL = false
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: infoLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text) else { continue }
                let urlString = "\(text[range])".hasPrefix("http") ? "\(text[range])" : "https://\(text[range])"
                if let url = URL(string: urlString) {
                    isFindURL = true
                    delegate?.openUrl(url)
                }
            }
        }
        if !isFindURL {
            infoLabel.attributedText?.enumerateAttribute(.link, in: NSRange(location: 0, length: text.utf16.count), options: [], using: { (object, range, _) in
                if gesture.didTapAttributedTextInLabel(label: infoLabel, inRange: range), let url = object as? URL {
                    delegate?.openUrl(url)
                }
            })
        }
    }
    
}

protocol OpenLinkDelegate: AnyObject {
    func openUrl(_ url: URL)
}
