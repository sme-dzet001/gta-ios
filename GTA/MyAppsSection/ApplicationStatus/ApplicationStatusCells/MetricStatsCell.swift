//
//  MetricStatsCell.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class MetricStatsCell: UITableViewCell {
    
    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var separator: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setUpCell(with data: ChartData, hideSeparator: Bool = false) {
        periodLabel.text = data.periodFullTitle
        let amount = data.value ?? 0
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let decimalFormattedAmount = numberFormatter.string(from: NSNumber(value: amount))
        amountLabel.text = decimalFormattedAmount
        separator.isHidden = hideSeparator
    }
    
}
