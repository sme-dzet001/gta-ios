//
//  SecondSendMessageView.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit

class SecondSendMessageView: UIView {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    class func instanceFromNib() -> SecondSendMessageView {
        let sendMessageView = UINib(nibName: "SecondSendMessageView", bundle: nil).instantiate(withOwner: self, options: nil).first as! SecondSendMessageView
        return sendMessageView
    }
    
    func setUpView() {
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(red: 229.0 / 255.0, green: 229.0 / 255.0, blue: 234.0 / 255.0, alpha: 1.0).cgColor
        textView.layer.cornerRadius = 10
        submitButton.layer.cornerRadius = 10
    }
    
}
