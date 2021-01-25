//
//  AboutContactsHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutContactsHeader: UIView {

    @IBOutlet weak var headerTitleLabel: UILabel!
    
    class func instanceFromNib() -> AboutContactsHeader {
        let header = UINib(nibName: "AboutContactsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! AboutContactsHeader
        return header
    }

}
