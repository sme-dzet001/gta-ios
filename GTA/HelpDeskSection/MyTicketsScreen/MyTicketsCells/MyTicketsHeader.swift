//
//  MyTicketsHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit

class MyTicketsHeader: UIView {

    @IBOutlet weak var headerTitleLabel: UILabel!
    
    weak var delegate: CreateTicketDelegate?
    
    class func instanceFromNib() -> MyTicketsHeader {
        let header = UINib(nibName: "MyTicketsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MyTicketsHeader
        return header
    }
    
    func setUpAction() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapped))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
        
    }
    
    @objc private func didTapped() {
        delegate?.createTicketDidPressed()
    }

}

protocol CreateTicketDelegate: class {
    func createTicketDidPressed()
}
