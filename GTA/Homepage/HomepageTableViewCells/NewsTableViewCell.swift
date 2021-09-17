//
//  NewsTableViewCell.swift
//  GTA
//
//  Created by Margarita N. Bock on 01.09.2021.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    var fullText: NSAttributedString?
    weak var delegate: TappedLabelDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bodyLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMoreDidTapped(gesture:)))
        tap.cancelsTouchesInView = false
        self.bodyLabel.addGestureRecognizer(tap)
    }
    
    @objc private func showMoreDidTapped(gesture: UITapGestureRecognizer) {
        guard let text = fullText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var isFindURL = false
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: bodyLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text), let url = getUrl(for: range, match: match) else { continue }
                isFindURL = true
                delegate?.openUrl(url)
                return
            }
        }
        if !isFindURL {
            fullText?.enumerateAttribute(.link, in: NSRange(location: 0, length: text.utf16.count), options: [], using: { (object, range, _) in
                if gesture.didTapAttributedTextInLabel(label: bodyLabel, inRange: range), let url = object as? URL {
                    delegate?.openUrl(url)
                    return
                }
            })
        }
        //bodyLabel.attributedText = fullText
        delegate?.moreButtonDidTapped(in: self)
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
        guard let text = bodyLabel.attributedText?.string else { return false }
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return false }
        if let _ = mailRegex.firstMatch(in: text, options: .anchored, range: match.range) {
            return true
        }
        return false
    }

    func setCollapse() {
        bodyLabel.numberOfLines = 3
        bodyLabel.sizeToFit()
        self.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.bodyLabel.attributedText = self?.fullText
            self?.bodyLabel.addReadMoreString("more")
        }
    }
    
}
