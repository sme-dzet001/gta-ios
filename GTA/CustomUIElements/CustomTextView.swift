//
//  CustomTextView.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.11.2020.
//

import UIKit

class CustomTextView: UITextView {
    
    private var placeholder: UILabel = UILabel()
    var placeHolderText: String?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setPlaceholder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        textViewDidChange(makeTextSmall: !(text ?? "").isEmpty)
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        textViewDidChange(makeTextSmall: true)
        return true
    }
    
    func setPlaceholder(makeTextSmall: Bool = false) {
        tintColor = UIColor(red: 204.0 / 255.0, green: 0 / 255.0, blue: 0 / 255.0, alpha: 1.0)
        let isNeedPlaceholderAnimation =  makeTextSmall || (isFirstResponder && text != nil)
        self.textContainerInset = UIEdgeInsets(top: 20, left: 13, bottom: 10, right: 13)
        placeholder.frame = CGRect(x: 17, y: !isNeedPlaceholderAnimation ? 20 : 2, width: self.frame.width, height: 18)
        let textSize: CGFloat = !isNeedPlaceholderAnimation ? 16.0 : 12.0
        placeholder.font = UIFont(name: "SFProText-Regular", size: textSize)
        placeholder.text = placeHolderText ?? "Comments"
        placeholder.textColor = UIColor(red: 142.0 / 255.0, green: 142.0 / 255.0, blue: 147.0 / 255.0, alpha: 1.0)
        self.addSubview(placeholder)
    }
    
    @objc func textViewDidChange(makeTextSmall: Bool = true) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.setPlaceholder(makeTextSmall: makeTextSmall)
            self.layoutIfNeeded()
        }, completion: nil)
    }

}
