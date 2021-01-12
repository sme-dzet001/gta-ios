//
//  AboutContactsCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutContactsCell: UITableViewCell {
    
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var dotSeparator: UIView!
    @IBOutlet weak var emailLabel: UILabel!
    
    var contactEmail: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        emailLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onEmailTap))
        emailLabel.addGestureRecognizer(tapGesture)
    }

    func setUpCell(with data: ContactData?) {
        if data?.contactPosition == nil || (data?.contactPosition ?? "").isEmpty {
            dotSeparator.isHidden = true
        }
        contactNameLabel.text = data?.contactName
        positionLabel.text = data?.contactPosition
        phoneNumberLabel.text = data?.phoneNumber
        emailLabel.attributedText = formEmailLink(from: data?.email)
    }
    
    private func formEmailLink(from text: String?) -> NSMutableAttributedString? {
        guard let text = text else { return nil }
        let font = UIFont(name: "SFProText-Regular", size: 16)!
        let attributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let res = NSMutableAttributedString(attributedString: attributedText)
        let wholeRange = NSRange(res.string.startIndex..., in: res.string)
        if let linkUrl = URL(string: "mailto:\(text)") {
            res.addAttribute(.link, value: linkUrl, range: wholeRange)
        }
        return res
    }
    
    @objc func onEmailTap() {
        makeEmailForAddress(contactEmail)
    }
    
    private func makeEmailForAddress(_ address: String?) {
        if let address = address, let addressURL = URL(string: "mailto:" + address) {
            UIApplication.shared.open(addressURL, options: [:], completionHandler: nil)
        }
    }
    
}
