//
//  MyTicketsHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit

class MyTicketsHeader: UIView {

    @IBOutlet weak var headerTitleLabel: UILabel!
    
    class func instanceFromNib() -> MyTicketsHeader {
        let header = UINib(nibName: "MyTicketsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MyTicketsHeader
        return header
    }

}
