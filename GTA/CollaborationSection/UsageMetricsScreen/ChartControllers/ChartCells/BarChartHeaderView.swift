//
//  BarChartHeaderView.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.07.2021.
//

import UIKit

class BarChartHeaderView: UIView {
    
    class func instanceFromNib() -> BarChartHeaderView {
        let header = UINib(nibName: "BarChartHeaderView", bundle: nil).instantiate(withOwner: self, options: nil).first as! BarChartHeaderView
        return header
    }
   
}
