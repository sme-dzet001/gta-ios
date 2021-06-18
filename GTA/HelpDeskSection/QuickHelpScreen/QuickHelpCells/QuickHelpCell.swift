//
//  QuickHelpCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

protocol QuickHelpCellDelegate: AnyObject {
    func quickHelpCellTapped(_ cell: QuickHelpCell, animationDuration: Double)
}

class QuickHelpCell: UITableViewCell {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextView: UITextView!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var questionLabelHeight: NSLayoutConstraint!
    
    private let animationPeriod = 0.4
    weak var delegate: QuickHelpCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        headerView.addGestureRecognizer(tapGesture)
//        answerTextView.translatesAutoresizingMaskIntoConstraints = true
//        answerTextView.sizeToFit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    func setUpCell(question: NSAttributedString?, questionLabelHeight: CGFloat, answer: NSAttributedString?, expandBtnType: ExpandButtonType) {
        questionLabel.attributedText = question
        self.questionLabelHeight.constant = questionLabelHeight
        answerTextView.attributedText = answer
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
