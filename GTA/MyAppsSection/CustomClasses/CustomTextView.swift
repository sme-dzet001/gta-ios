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
    
    func setPlaceholder() {
        self.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 10, right: 10)
        placeholder.frame = CGRect(x: 10, y: text.isEmpty ? 20 : 2, width: self.frame.width, height: 18)
        let textSize: CGFloat = text.isEmpty ? 16.0 : 12.0
        placeholder.font = UIFont(name: "SFProText-Regular", size: textSize)
        placeholder.text = placeHolderText ?? "Comments"
        placeholder.textColor = UIColor(red: 142.0 / 255.0, green: 142.0 / 255.0, blue: 147.0 / 255.0, alpha: 1.0)
        self.addSubview(placeholder)
    }
    
    @objc func textViewDidChange() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.setPlaceholder()
            self.layoutIfNeeded()
        }, completion: nil)
    }

}
