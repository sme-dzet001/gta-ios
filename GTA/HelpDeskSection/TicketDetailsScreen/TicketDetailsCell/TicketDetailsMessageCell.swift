//
//  TicketDetailsMessageCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit

class TicketDetailsMessageCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func fillCell(with data: GSDTicketComment?) {
        nameLabel.text = data?.createdBy
        dateLabel.text = data?.createdDate?.getFormattedDateStringForMyTickets()
        messageLabel.text = data?.body
    }
    
}
