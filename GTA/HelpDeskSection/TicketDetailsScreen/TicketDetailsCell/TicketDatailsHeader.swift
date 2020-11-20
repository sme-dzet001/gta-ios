//
//  TicketDatailsHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit

class TicketDatailsHeader: UIView {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var issueLabel: UILabel!
    
    class func instanceFromNib() -> TicketDatailsHeader {
        let header = UINib(nibName: "TicketDatailsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! TicketDatailsHeader
        return header
    }
    
    func fillHeaderLabels(with data: TicketData?) {
        numberLabel.text = data?.number
        issueLabel.text = data?.issue
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.neededDateFormat
        dateLabel.text = dateFormatterPrint.string(from: data?.date ?? Date())
        let status = data?.status ?? .closed
        switch status {
        case .open:
            statusLabel.textColor = UIColor(red: 52.0 / 255.0, green: 199.0 / 255.0, blue: 89.0 / 255.0, alpha: 1)
            statusLabel.text = "Open"
        default:
            statusLabel.textColor = UIColor(red: 255.0 / 255.0, green: 62.0 / 255.0, blue: 51.0 / 255.0, alpha: 1)
            statusLabel.text = "Closed"
        }
    }
    
}
