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
    
    weak var delegate: TappedLabelDelegate?
    var fullText: NSAttributedString?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMoreDidTapped(gesture:)))
        tap.cancelsTouchesInView = false
        newsTextLabel.isUserInteractionEnabled = true
        newsTextLabel.setLineHeight(lineHeight: 10)
        newsTextLabel.addGestureRecognizer(tap)
    }
    
    func setupCell(text: String?) {
        let decodedText = formNewsBody(from: text)
        decodedText?.setFontFace(font: UIFont(name: "SFProText-Light", size: 16)!)
        fullText = decodedText
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
    
    @objc private func showMoreDidTapped(gesture: UITapGestureRecognizer) {
        guard let text = fullText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var isFindURL = false
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: newsTextLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text), let url = getUrl(for: range, match: match) else { continue }
                isFindURL = true
                print(url)
                delegate?.openUrl(url)
                return
            }
        }
        if !isFindURL {
            fullText?.enumerateAttribute(.link, in: NSRange(location: 0, length: text.utf16.count), options: [], using: { (object, range, _) in
                if gesture.didTapAttributedTextInLabel(label: newsTextLabel, inRange: range), let url = object as? URL {
                    delegate?.openUrl(url)
                    print(url)
                    return
                }
            })
        }
    }
    
    private func getUrl(for range: Range<String.Index>, match: NSTextCheckingResult) -> URL? {
        guard let text = (fullText?.string) else { return nil }
        if isMatchEmail(match: match), let url = URL(string: "mailto:\(text[range])") {
            return url
        }
        if let url = URL(string: "\(text[range])") {
            return url
        }
        return nil
    }
    
    private func isMatchEmail(match: NSTextCheckingResult) -> Bool {
        guard let text = newsTextLabel.attributedText?.string else { return false }
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return false }
        if let _ = mailRegex.firstMatch(in: text, options: .anchored, range: match.range) {
            return true
        }
        return false
    }
}
