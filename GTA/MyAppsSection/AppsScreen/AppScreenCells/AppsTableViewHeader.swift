//
//  AppsTableViewHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class AppsTableViewHeader: UIView {
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    class func instanceFromNib() -> AppsTableViewHeader {
        let header = UINib(nibName: "AppsTableViewHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! AppsTableViewHeader
        return header
    }

}
