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
    
    var articleText: String = "" {
        didSet {
            articleTextView?.text = articleText
        }
    }
    var panScrollable: UIScrollView?
    
    var showDragIndicator: Bool {
        return false
    }
    var initialHeight: CGFloat = 0.0
    weak var appearanceDelegate: PanModalAppearanceDelegate?
    
    private var heightObserver: NSKeyValueObservation?
    private var gestureStartPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var presentationView: UIView? {
        return self.presentationController?.containerView?.subviews.filter({$0 is DimmedView}).first
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
    
    var allowsTapToDismiss: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        articleTextView.text = articleText
        articleTextView.textContainerInset = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTextViewLayout()
        })
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(newsDidScroll))
        panGesture.minimumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        presentationView?.addGestureRecognizer(panGesture)
    }
    
    private func setUpTextViewLayout() {
        let position = UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
        articleTextViewBottom.constant = position > 0 ? self.view.frame.height - position : 0
        self.view.layoutIfNeeded()
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
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var panModalBackgroundColor: UIColor {
        return .clear
    }
    
    func panModalWillDismiss() {
        appearanceDelegate?.panModalDidDissmiss()
    }
 
    deinit {
        heightObserver?.invalidate()
    }
}
