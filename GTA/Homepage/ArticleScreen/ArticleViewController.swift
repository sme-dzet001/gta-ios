//
//  ArticleViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.11.2020.
//

import UIKit
import PanModal

class ArticleViewController: UIViewController {
    
    @IBOutlet weak var articleTextView: UITextView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var articleTextViewBottom: NSLayoutConstraint!
    
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
    
    var initialHeight: CGFloat = 0.0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private var gestureStartPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var heightObserver: NSKeyValueObservation?
    weak var appearanceDelegate: PanModalAppearanceDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        articleTextView.delegate = self
        if let attributedText = attributedArticleText {
            attributedText.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedText.length), options: .longestEffectiveRangeNotRequired) { attributes, range, _ in
                if attributes != nil {
                    attributedText.insert(NSAttributedString(string: " "), at: range.location)
                }
                
            }
            articleTextView.attributedText = attributedArticleText
        } else {
            articleTextView.text = articleText
        }
        articleTextView.textContainerInset = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        setAccessibilityIdentifiers()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurToView()
        addHeightObservation()
        //addGesture()
        configureBlurViewPosition(isInitial: true)
        if view.window?.safeAreaInsets.top ?? 0 <= 24 {
            articleTextViewBottom?.constant = 15
        }
    }
    
    private func addHeightObservation() {
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.configureBlurViewPosition()
        })
    }
    
    override func viewDidLayoutSubviews() {
        configureBlurViewPosition()
    }
    
    private func setAccessibilityIdentifiers() {
        closeButton.accessibilityIdentifier = "ArticleCloseButton"
        articleTextView.accessibilityIdentifier = "ArticleTextView"
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
        dismissModal()
    }
    
    @objc private func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setParagraphStyle() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 22
        
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
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
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

extension ArticleViewController: PanModalPresentable {
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    
    var panScrollable: UIScrollView? {
        return articleTextView
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    private var presentationView: UIView? {
        return self.presentationController?.containerView?.subviews.filter({$0 is DimmedView}).first
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
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
    
    var panModalBackgroundColor: UIColor {
        return UIColor(hex: 0x000000, alpha: 0.4)
    }
   
}
