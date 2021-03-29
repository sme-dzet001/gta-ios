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
    @IBOutlet weak var openDateLabel: UILabel!
    //@IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var statusDateTitleLabel: UILabel!
    @IBOutlet weak var separatorUnderStatusDate: UIView!
    @IBOutlet weak var statusDateStackView: UIStackView!
    @IBOutlet weak var statusDateLabel: UILabel!
    @IBOutlet weak var ticketSubject: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: GSDMyTicketsRow?, hideSeparator: Bool = false) {
        ticketSubject.text = data?.subject
        separatorUnderStatusDate.isHidden = data?.closeDate == nil ? true : false
        switch data?.status {
        case .new, .open:
            statusLabel.text = data?.status == .new ? "New" : "Open"
            statusDateStackView.isHidden = true
            //separatorUnderStatusDate.isHidden = true
            statusLabel.textColor = UIColor(hex: 0x34C759)
        case .closed:
            statusLabel.text = "Closed"
            statusDateTitleLabel.text = "Close Date"
            //separatorUnderStatusDate.isHidden = false
            statusDateStackView.isHidden = false
            statusLabel.textColor = UIColor(hex: 0xFF3E33)
        default: statusLabel.text = ""
        }
        numberLabel.text = data?.ticketNumber
        openDateLabel.text = data?.openDate?.getFormattedDateStringForMyTickets()
        statusDateLabel.text = data?.closeDate?.getFormattedDateStringForMyTickets()
        //separatorView.isHidden = hideSeparator
    }
    
}

