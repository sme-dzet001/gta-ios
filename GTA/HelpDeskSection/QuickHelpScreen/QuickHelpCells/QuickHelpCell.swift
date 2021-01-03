//
//  QuickHelpCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

protocol QuickHelpCellDelegate: class {
    func quickHelpCellTapped(_ cell: QuickHelpCell, animationDuration: Double)
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
