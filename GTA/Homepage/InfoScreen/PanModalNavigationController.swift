//
//  PanModalNavigationController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit
import PanModal

class PanModalNavigationController: UINavigationController, PanModalPresentable {
    
    var initialHeight: CGFloat = 0.0
    var panScrollable: UIScrollView?
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(initialHeight + 10)
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
}
