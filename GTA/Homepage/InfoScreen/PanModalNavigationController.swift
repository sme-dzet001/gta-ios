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
        return .contentHeight(initialHeight)
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
}

extension UINavigationController {
    
    func pushWithFadeAnimationVC(_ vc: UIViewController) {
        addTransitionAnimation()
        self.pushViewController(vc, animated: false)
    }
    
    func popWithFadeAnimation() {
        addTransitionAnimation()
        self.popViewController(animated: false)
    }
    
    private func addTransitionAnimation() {
        let transition: CATransition = CATransition()
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        self.view.layer.add(transition, forKey: nil)
    }
    
}
