//
//  MyTicketsFilterHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.06.2021.
//

import UIKit

class MyTicketsFilterHeader: UIView {

    @IBOutlet weak var sortView: UIView!
    @IBOutlet weak var filterView: UIView!
    
    class func instanceFromNib() -> MyTicketsFilterHeader {
        let header = UINib(nibName: "MyTicketsFilterHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MyTicketsFilterHeader
        return header
    }
    
    private func selectView(_ selectedView: UIView) {
        UIView.animate(withDuration: 0.3) {
            selectedView.layer.borderWidth = 1
            selectedView.layer.borderColor = UIColor(hex: 0xCC0000).cgColor
            if selectedView == self.sortView {
                self.filterView.layer.borderWidth = 0
            } else {
                self.sortView.layer.borderWidth = 0
            }
        }
    }

}

extension MyTicketsFilterHeader: SortFilterDelegate {
    func sortDidPressed() {
        selectView(sortView)
    }
    
    func filterDidPressed() {
        selectView(filterView)
    }
    
}
