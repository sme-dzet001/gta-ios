//
//  ServiceDeskContactCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 04.12.2020.
//

import UIKit

class ServiceDeskContactCell: UITableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var funFactLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var descLabelBottom: NSLayoutConstraint!
    @IBOutlet weak var funFactLabelBottom: NSLayoutConstraint!
    
    var imageUrl: String?
    var contactEmail: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        emailLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onEmailTap))
        emailLabel.addGestureRecognizer(tapGesture)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        activityIndicator.stopAnimating()
    }

    func setUpCell(with data: TeamContactsRow?) {
        photoImageView.layer.cornerRadius = photoImageView.frame.size.width / 2
        contactNameLabel.text = data?.contactName
        positionLabel.text = data?.contactPosition
        descriptionLabel.text = data?.contactBio
        funFactLabel.text = data?.contactFunFact
        emailLabel.attributedText = formEmailLink(from: data?.contactEmail)
        locationLabel.text = data?.contactLocation
        let locationIsMissing = data?.contactLocation == nil || (data?.contactLocation ?? "").isEmpty
        locationIcon.isHidden = locationIsMissing
        setUpMargins(descIsEmpty: data?.contactBio?.isEmpty ?? true, funFactIsEmpty: data?.contactFunFact?.isEmpty ?? true)
        addAccessibilityIdentifiers()
    }
    
    private func addAccessibilityIdentifiers() {
        contactNameLabel.accessibilityIdentifier = "ServiceDeskContactsContactNameLabel"
        positionLabel.accessibilityIdentifier = "ServiceDeskContactsContactPositionLabel"
        descriptionLabel.accessibilityIdentifier = "ServiceDeskContactsContactDescriptionLabel"
        funFactLabel.accessibilityIdentifier = "ServiceDeskContactsContactFunFactLabel"
        emailLabel.accessibilityIdentifier = "ServiceDeskContactsContactEmailLabel"
        locationLabel.accessibilityIdentifier = "ServiceDeskContactsContactLocationLabel"
    }
    
    private func setUpMargins(descIsEmpty: Bool, funFactIsEmpty: Bool) {
        switch (descIsEmpty, funFactIsEmpty) {
        case (false, false):
            descLabelBottom.constant = 12
            funFactLabelBottom.constant = 14
        case (false, true), (true, false):
            descLabelBottom.constant = 0
            funFactLabelBottom.constant = 14
        case (true, true):
            descLabelBottom.constant = 8
            funFactLabelBottom.constant = 0
        }
    }
    
    private func formEmailLink(from text: String?) -> NSMutableAttributedString? {
        guard let text = text else { return nil }
        let font = UIFont(name: "SFProText-Regular", size: 14)!
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
