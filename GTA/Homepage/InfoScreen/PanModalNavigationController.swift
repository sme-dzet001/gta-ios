//
//  PanModalNavigationController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit
import PanModal

class PanModalNavigationController: UINavigationController, PanModalPresentable {
    
    var forceOfficeSelection = false
    var initialHeight: CGFloat = 0.0
    var panScrollable: UIScrollView?
    
    var shortFormHeight: PanModalHeight {
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return PanModalHeight.contentHeight(coefficient - (view.window?.safeAreaInsets.bottom ?? 0))
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
    
    var allowsTapToDismiss: Bool {
        return !forceOfficeSelection
    }
    
    var allowsDragToDismiss: Bool {
        return !forceOfficeSelection
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc private func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
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
