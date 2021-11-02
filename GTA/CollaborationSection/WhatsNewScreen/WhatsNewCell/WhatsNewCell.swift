//
//  WhatsNewCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit
import SDWebImage

class WhatsNewCell: UITableViewCell {
    
    @IBOutlet weak var mainImageView: SDAnimatedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        
    var imageUrl: String?
    var body: String?
    var fullText: NSAttributedString?
    weak var delegate: TappedLabelDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.descriptionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMoreDidTapped(gesture:)))
        tap.cancelsTouchesInView = false
        self.descriptionLabel.addGestureRecognizer(tap)
        setAccessibilityIdentifiers()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.stopAnimating()
        self.mainImageView.stopAnimating()
        self.mainImageView.image = nil
        self.mainImageView.sd_cancelCurrentImageLoad()
        //self.mainImageView.clear()
        self.layoutIfNeeded()
    }
    
    private func setAccessibilityIdentifiers() {
        mainImageView.accessibilityIdentifier = "WhatsNewCellImageView"
        titleLabel.accessibilityIdentifier = "WhatsNewCellTitleLabel"
        subtitleLabel.accessibilityIdentifier = "WhatsNewCellSubtitleLabel"
        descriptionLabel.accessibilityIdentifier = "WhatsNewCellDescriptionLabel"
    }
    
    func setDate(_ date: String?) {
        if let date = date {
            subtitleLabel.text = date.getFormattedDateStringForNews()
        } else {
            subtitleLabel.text = date
        }
    }
    
    @objc private func showMoreDidTapped(gesture: UITapGestureRecognizer) {
        guard let text = fullText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var isFindURL = false
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: descriptionLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text), let url = getUrl(for: range, match: match) else { continue }
                isFindURL = true
                delegate?.openUrl(url)
                return
            }
        }
        if !isFindURL {
            fullText?.enumerateAttribute(.link, in: NSRange(location: 0, length: text.utf16.count), options: [], using: { (object, range, _) in
                if gesture.didTapAttributedTextInLabel(label: descriptionLabel, inRange: range), let url = object as? URL {
                    delegate?.openUrl(url)
                    return
                }
            })
        }
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
        guard let text = descriptionLabel.attributedText?.string else { return false }
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return false }
        if let _ = mailRegex.firstMatch(in: text, options: .anchored, range: match.range) {
            return true
        }
        return false
    }
    
    func setCollapse() {
        descriptionLabel.numberOfLines = 3
        descriptionLabel.sizeToFit()
        self.layoutIfNeeded()
        descriptionLabel.attributedText = fullText
        descriptionLabel.addReadMoreString("more")
    }
    
}
