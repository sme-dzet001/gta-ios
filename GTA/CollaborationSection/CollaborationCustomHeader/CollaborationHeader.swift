//
//  CollaborationHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.03.2021.
//

import UIKit

class CollaborationHeader: UIView {

    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var titleCenterX: NSLayoutConstraint?
    
    class func instanceFromNib() -> CollaborationHeader {
        let header = UINib(nibName: "CollaborationHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! CollaborationHeader
        return header
    }
    
    func hideViews() {
        headerTitle.isHidden = true
        headerImageView.isHidden = true
    }
    
    func showViews() {
        changeConstraintsIfNeeded()
        if headerTitle.text == nil || headerTitle.text == "" {
            headerTitle.text = "Collaboration"
        }
        headerTitle.isHidden = false
        headerImageView.isHidden = false
    }
    
    private func changeConstraintsIfNeeded() {
        guard let _ = titleCenterX else { return }
        var newConstraint = titleCenterX!
        if headerTitle.text == nil || headerTitle.text == "" {
            newConstraint = titleCenterX!.constraintWithMultiplier(1.0)
        } else {
            newConstraint = titleCenterX!.constraintWithMultiplier(1.1)
        }
        self.removeConstraint(titleCenterX!)
        self.addConstraint(newConstraint)
    }
    
}
