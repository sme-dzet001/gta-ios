//
//  SendMessageView.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit

class SendMessageView: UIView {

    @IBOutlet weak var textView: CustomTextView!
    @IBOutlet weak var sendButton: UIButton!
    
    weak var sendButtonDelegate: SendButtonPressedDelegate?
    
    class func instanceFromNib() -> SendMessageView {
        let sendMessageView = UINib(nibName: "SendMessageView", bundle: nil).instantiate(withOwner: self, options: nil).first as! SendMessageView
        return sendMessageView
    }
    
    func setUpTextView() {
        textView.placeHolderText = "Type a message"
        textView.setPlaceholder()
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red: 229.0 / 255.0, green: 229.0 / 255.0, blue: 234.0 / 255.0, alpha: 1.0).cgColor
    }
    
    @IBAction func sendButtonDidPressed(_ sender: UIButton) {
        sendButtonDelegate?.sendButtonDidPressed()
    }
    
}

protocol SendButtonPressedDelegate: AnyObject {
    func sendButtonDidPressed()
}
