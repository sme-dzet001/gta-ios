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
    
    private var centerHeaderLabel: UILabel! {
        didSet {
            centerHeaderLabel.text = "Collaboration"
            centerHeaderLabel.textAlignment = .center
            centerHeaderLabel.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: self.frame.height)
            centerHeaderLabel.center = self.center
            if let font = UIFont(name: "SFProText-Medium", size: 20) {
                centerHeaderLabel.font = font
            }
        }
    }
    
    class func instanceFromNib() -> CollaborationHeader {
        let header = UINib(nibName: "CollaborationHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! CollaborationHeader
        return header
    }
    
    func hideViews() {
        headerTitle.isHidden = true
        headerImageView.isHidden = true
        headerSubtitle.isHidden = true
        if let label = centerHeaderLabel {
            guard self.subviews.contains(label) else {return}
            centerHeaderLabel.removeFromSuperview()
        }
    }
    
    func showViews() {
        if headerTitle.text == nil || headerTitle.text == "" {
            centerHeaderLabel = UILabel()
            self.addSubview(centerHeaderLabel)
        }
        headerTitle.isHidden = false
        if headerSubtitle.text == nil || headerSubtitle.text == "" {
            headerSubtitle.isHidden = true
        }
        headerSubtitle.isHidden = false
        headerImageView.isHidden = false
    }
}
