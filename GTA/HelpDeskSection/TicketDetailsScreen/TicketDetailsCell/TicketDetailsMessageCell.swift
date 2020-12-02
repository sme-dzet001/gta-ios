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
    
    func fillCell(with data: TicketComment?) {
        nameLabel.text = data?.author
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.ticketsSectionDateFormat
        // hardcoding date similar to Figma for now
        dateLabel.text = "Wed 15, 2020 10:30 -5 GMT" //dateFormatterPrint.string(from: data?.date ?? Date())
        messageLabel.text = data?.text
    }
    
}
