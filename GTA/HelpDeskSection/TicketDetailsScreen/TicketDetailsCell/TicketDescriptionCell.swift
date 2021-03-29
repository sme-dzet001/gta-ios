//
//  TicketDescriptionCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 23.03.2021.
//

import UIKit

class TicketDescriptionCell: UITableViewCell {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ticketSubjectLabel: UILabel!
    @IBOutlet weak var ticketNumberLabel: UILabel!
    @IBOutlet weak var openDateLabel: UILabel!
    @IBOutlet weak var statusTitleLabel: UILabel!
    @IBOutlet weak var statusDateLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var approvalStatusLabel: UILabel!
    @IBOutlet weak var SLAPriorityLabel: UILabel!
    @IBOutlet weak var decriptionLabel: UILabel!
    @IBOutlet weak var finalNoteLabel: UILabel!
    @IBOutlet weak var SLAPriorityView: UIStackView!
    @IBOutlet weak var approvalStatusView: UIStackView!
    @IBOutlet weak var finalNoteStackView: UIStackView!
    @IBOutlet weak var statusDateView: UIStackView!
    @IBOutlet weak var decriptionStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: TicketData?) {
        guard let data = data else { return }
        ticketSubjectLabel.text = data.ticketSubject ?? ticketSubjectLabel.text
        switch data.status {
        case .new:
            statusLabel.text = "New"
            statusLabel.textColor = UIColor(hex: 0x34C759)
        case .closed:
            statusLabel.text = "Closed"
            statusTitleLabel.text = "Close Date"
            //separatorUnderStatusDate.isHidden = false
            //statusDateStackView.isHidden = false
            statusLabel.textColor = UIColor(hex: 0xFF3E33)
        }
        //openDateLabel.text = data.openDate
    }
    
}
