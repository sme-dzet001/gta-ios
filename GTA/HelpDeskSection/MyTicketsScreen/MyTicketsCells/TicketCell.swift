//
//  TicketCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit

class TicketCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: TicketData, hideSeparator: Bool = false) {
        switch data.status {
        case .open:
            statusLabel.text = "Open"
            statusLabel.textColor = UIColor(hex: 0x34C759)
        case .closed:
            statusLabel.text = "Closed"
            statusLabel.textColor = UIColor(hex: 0xFF3E33)
        }
        numberLabel.text = data.number
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.ticketsSectionDateFormat
        // hardcoding date similar to Figma for now
        dateLabel.text = "Wed 15, 2020 10:30 -5 GMT" //dateFormatterPrint.string(from: data.date ?? Date())
        separatorView.isHidden = hideSeparator
    }
    
}
