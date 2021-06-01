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
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var articleTextViewBottom: NSLayoutConstraint!
    
    private var heightObserver: NSKeyValueObservation?
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    var articleText: String?
    var attributedArticleText: NSMutableAttributedString? {
        didSet {
            let animation = CATransition()
            animation.type = .fade
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            articleTextView?.layer.add(animation, forKey: "changeTextTransition")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            paragraphStyle.paragraphSpacing = 22
            attributedArticleText?.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedArticleText?.length ?? 0))
            articleTextView?.attributedText = attributedArticleText
            if let _ = articleTextView {
                panModalSetNeedsLayoutUpdate()
            }
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
        articleTextView.delegate = self
        if let _ = attributedArticleText {
            articleTextView.attributedText = attributedArticleText
        } else {
            articleTextView.text = articleText
        }
        articleTextView.textContainerInset = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        setAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurToView()
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.configureBlurViewPosition()
        })
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(newsDidScroll))
        panGesture.minimumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        presentationView?.addGestureRecognizer(panGesture)
        configureBlurViewPosition(isInitial: true)
        if view.window?.safeAreaInsets.top ?? 0 <= 24 {
            articleTextViewBottom?.constant = 15
        }
    }
    
    override func viewDidLayoutSubviews() {
        configureBlurViewPosition()
    }
    
    private func setAccessibilityIdentifiers() {
        closeButton.accessibilityIdentifier = "ArticleCloseButton"
        articleTextView.accessibilityIdentifier = "ArticleTextView"
    }
    
    @objc func newsDidScroll(gesture: UIPanGestureRecognizer) {
        let velocity = gesture.velocity(in: presentationView)
        if gesture.state == .began {
            gestureStartPoint = velocity
        } else if gesture.state == .changed {
            gesture.state = .ended
            let xValue = gestureStartPoint.x > velocity.x ?  gestureStartPoint.x - velocity.x : gestureStartPoint.x + velocity.x
            let yValue = gestureStartPoint.y > velocity.y ?  gestureStartPoint.y - velocity.y : gestureStartPoint.y + velocity.y
            let direction: UICollectionView.ScrollPosition = gestureStartPoint.x > velocity.x ? .left : .right
            if xValue > yValue {
                appearanceDelegate?.needScrollToDirection(direction)
                articleTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }
    
    private func configureBlurViewPosition(isInitial: Bool = false) {
        guard position > 0 else { return }
        blurView.frame.origin.y = !isInitial ? position - blurView.frame.height: initialHeight - 44
        self.view.layoutIfNeeded()
    }
        
    func addBlurToView() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func panModalWillDismiss() {
        appearanceDelegate?.panModalDidDissmiss()
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        switch state {
        case .shortForm:
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = 1
            }
        default:
            return
        }
    }
    
    deinit {
        heightObserver?.invalidate()
    }
}

extension ArticleViewController: UITextViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleBlurShowing(animated: true)
    }
    
    private func handleBlurShowing(animated: Bool) {
        let isReachedBottom = articleTextView.contentOffset.y >= (articleTextView.contentSize.height - articleTextView.frame.size.height).rounded(.towardZero)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = isReachedBottom ? 0 : 1
            }
        } else {
            blurView.alpha = isReachedBottom ? 0 : 1
        }
    }
    
}
