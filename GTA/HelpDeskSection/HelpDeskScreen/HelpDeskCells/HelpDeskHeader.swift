//
//  HelpDeskHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 30.11.2020.
//

import UIKit

class HelpDeskHeader: UIView {
    
    class func instanceFromNib() -> HelpDeskHeader {
        let header = UINib(nibName: "HelpDeskHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! HelpDeskHeader
        return header
    }

}
