//
//  ProductionAlertCounterCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 21.04.2021.
//

import UIKit

class ProductionAlertCounterCell: UITableViewCell {

    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var updatesNumberLabel: UILabel!
    @IBOutlet weak var alertsNumberParentView: UIView!
    
    weak var popoverShowDelegate: AlertPopoverShowDelegate?
    weak var showAlertScreenDelegate: ShowAlertScreenDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(showAlertDelegate))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
    }
    
    @objc private func showAlertDelegate() {
        showAlertScreenDelegate?.showAlertScreen()
    }
    
    func setAlert(alertCount: Int?, setTap: Bool = true) {
        if let number = alertCount {
            self.alertsNumberParentView.isHidden = false
            self.updatesNumberLabel.text = "\(number)" //: nil
            guard setTap else { return }
            setTapGesture()
        } else {
            self.alertsNumberParentView.isHidden = true
            self.updatesNumberLabel.isHidden = true
        }
        
    }
    
    private func setTapGesture() {
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(showPreview))
        longTap.cancelsTouchesInView = false
        self.alertsNumberParentView.addGestureRecognizer(longTap)
    }
    
    @objc private func showPreview() {
        var frame = alertsNumberParentView.frame
        frame.origin.x -= alertsNumberParentView.frame.width / 2
        popoverShowDelegate?.showAlertPopover(for: frame, sourceView: self)
    }
    

}

protocol AlertPopoverShowDelegate: AnyObject {
    func showAlertPopover(for rect: CGRect, sourceView: UIView)
}

protocol ShowAlertScreenDelegate: AnyObject {
    func showAlertScreen()
}
