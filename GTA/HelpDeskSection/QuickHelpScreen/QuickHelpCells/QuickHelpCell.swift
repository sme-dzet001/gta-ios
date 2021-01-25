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
    
    private let animationPeriod = 0.4
    weak var delegate: QuickHelpCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        expandButton.addGestureRecognizer(tapGesture)
        self.answerLabel.isUserInteractionEnabled = true
        self.answerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tryOpenLink(gesture:))))
    }
    
    @objc private func tryOpenLink(gesture: UITapGestureRecognizer) {
        guard let text = answerLabel.attributedText?.string else { return }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if gesture.didTapAttributedTextInLabel(label: answerLabel, inRange: match.range) {
                guard let range = Range(match.range, in: text), let url = URL(string: "\(text[range])")  else { continue }
                delegate?.openUrl(url)
            }
        }
    }
    
    func setUpCell(question: String?, answer: NSAttributedString?, expandBtnType: ExpandButtonType) {
        questionLabel.text = question
        answerLabel.attributedText = answer
        switch expandBtnType {
        case .plus:
            expandButton.setImage(UIImage(named: "plus_icon"), for: .normal)
        case .minus:
            expandButton.setImage(UIImage(named: "minus_icon"), for: .normal)
        }
    }

    @objc func onTap() {
        delegate?.quickHelpCellTapped(self, animationDuration: animationPeriod)
    }
    
}
