//
//  QuickHelpCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

protocol QuickHelpCellDelegate: class {
    func quickHelpCellTapped(_ cell: QuickHelpCell, animationDuration: Double)
    func openUrl(_ url: URL)
}

class QuickHelpCell: UITableViewCell {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var questionLabelHeight: NSLayoutConstraint!
    
    private let animationPeriod = 0.4
    weak var delegate: QuickHelpCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        headerView.addGestureRecognizer(tapGesture)
        self.answerLabel.isUserInteractionEnabled = true
        self.answerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tryOpenLink(gesture:))))
    }
    
    @objc private func tryOpenLink(gesture: UITapGestureRecognizer) {
        guard let text = answerLabel.attributedText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var isFindURL = false
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: answerLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text), let url = getUrl(for: range, match: match) else { continue }
                isFindURL = true
                delegate?.openUrl(url)
            }
        }
        if !isFindURL {
            answerLabel.attributedText?.enumerateAttribute(.link, in: NSRange(location: 0, length: text.utf16.count), options: [], using: { (object, range, _) in
                if gesture.didTapAttributedTextInLabel(label: answerLabel, inRange: range), let url = object as? URL {
                    delegate?.openUrl(url)
                }
            })
        }
    }
    
    private func getUrl(for range: Range<String.Index>, match: NSTextCheckingResult) -> URL? {
        let text = (answerLabel.attributedText?.string)!
        if isMatchEmail(match: match), let url = URL(string: "mailto:\(text[range])") {
            return url
        }
        if let url = URL(string: "\(text[range])") {
            return url
        }
        return nil
    }
    
    private func isMatchEmail(match: NSTextCheckingResult) -> Bool {
        guard let text = answerLabel.attributedText?.string else { return false }
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return false }
        if let _ = mailRegex.firstMatch(in: text, options: .anchored, range: match.range) {
            return true
        }
        return false
    }
    
    func setUpCell(question: NSAttributedString?, questionLabelHeight: CGFloat, answer: NSAttributedString?, expandBtnType: ExpandButtonType) {
        questionLabel.attributedText = question
        self.questionLabelHeight.constant = questionLabelHeight
        answerLabel.attributedText = answer
        switch expandBtnType {
        case .expand:
            expandButton.setImage(UIImage(named: "disclosure_arrow_down"), for: .normal)
        case .collapse:
            expandButton.setImage(UIImage(named: "disclosure_arrow_up"), for: .normal)
        }
    }

    @objc func onTap() {
        delegate?.quickHelpCellTapped(self, animationDuration: animationPeriod)
    }
    
}
