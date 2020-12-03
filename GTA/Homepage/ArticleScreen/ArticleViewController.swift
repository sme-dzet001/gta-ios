//
//  ArticleViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.11.2020.
//

import UIKit
import PanModal

class ArticleViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var articleTextView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var articleTextViewBottom: NSLayoutConstraint!
    
    var articleText: String? = "" {
        didSet {
            let animation = CATransition()
            animation.type = .fade
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            articleTextView?.layer.add(animation, forKey: "changeTextTransition")
            articleTextView?.text = articleText
        }
    }
    
    var panScrollable: UIScrollView? {
        return articleTextView
    }
    
    var showDragIndicator: Bool {
        return false
    }
    var initialHeight: CGFloat = 0.0
    weak var appearanceDelegate: PanModalAppearanceDelegate?
    
    private var gestureStartPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var presentationView: UIView? {
        return self.presentationController?.containerView?.subviews.filter({$0 is DimmedView}).first
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(initialHeight + 10)
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var allowsDragToDismiss: Bool {
        return false
    }
    
    var allowsTapToDismiss: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var panModalBackgroundColor: UIColor {
        return .clear
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        articleTextView.text = articleText
        articleTextView.textContainerInset = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(newsDidScroll))
        panGesture.minimumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        presentationView?.addGestureRecognizer(panGesture)
    }
    
    @objc func newsDidScroll(gesture: UIPanGestureRecognizer) {
        let velocity = gesture.velocity(in: presentationView)
        if gesture.state == .began {
            gestureStartPoint = velocity
        } else if gesture.state == .ended {
            let xValue = gestureStartPoint.x > velocity.x ?  gestureStartPoint.x - velocity.x : gestureStartPoint.x + velocity.x
            let yValue = gestureStartPoint.y > velocity.y ?  gestureStartPoint.y - velocity.y : gestureStartPoint.y + velocity.y
            let direction: UICollectionView.ScrollPosition = gestureStartPoint.x > velocity.x ? .left : .right
            if xValue > yValue {
                appearanceDelegate?.needScrollToDirection(direction)
                articleTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func panModalWillDismiss() {
        appearanceDelegate?.panModalDidDissmiss()
    }
}
