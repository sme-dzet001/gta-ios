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
    @IBOutlet weak var headerSubtitle: UILabel!
    
    class func instanceFromNib() -> CollaborationHeader {
        let header = UINib(nibName: "CollaborationHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! CollaborationHeader
        return header
    }
    
    func hideViews() {
        headerTitle.isHidden = true
        headerImageView.isHidden = true
        headerSubtitle.isHidden = true
    }
    
    func showViews() {
        if headerTitle.text == nil || headerTitle.text == "" {
            headerTitle.text = "Collaboration"
        }
        headerTitle.isHidden = false
        if headerSubtitle.text == nil || headerSubtitle.text == "" {
            headerSubtitle.isHidden = true
        }
        headerSubtitle.isHidden = false
        headerImageView.isHidden = false
    }
}
