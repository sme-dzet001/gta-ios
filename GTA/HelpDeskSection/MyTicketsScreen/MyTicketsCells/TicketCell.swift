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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: TicketData) {
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
        dateFormatterPrint.dateFormat = String.neededDateFormat
        dateLabel.text = dateFormatterPrint.string(from: data.date ?? Date())
    }
    
}
