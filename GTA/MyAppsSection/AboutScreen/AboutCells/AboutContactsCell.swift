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
    @IBOutlet weak var emailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: ContactData?) {
        contactNameLabel.text = data?.contactName
        positionLabel.text = data?.contactPosition
        phoneNumberLabel.text = data?.phoneNumber
        emailLabel.text = data?.email
    }
    
}
