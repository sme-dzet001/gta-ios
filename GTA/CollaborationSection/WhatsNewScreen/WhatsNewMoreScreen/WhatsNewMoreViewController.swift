//
//  WhatsNewMoreViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit

class WhatsNewMoreViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var infoTextView: UITextView!
    
    var dataProvider: CollaborationDataProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        infoTextView.delegate = self
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.blurView.isHidden = false
        addBlurToView()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        handleBlurShowing(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func handleBlurShowing(animated: Bool) {
        let isReachedBottom = infoTextView.contentOffset.y >= (infoTextView.contentSize.height - infoTextView.frame.size.height).rounded(.towardZero)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = isReachedBottom ? 0 : 1
            }
        } else {
            blurView.alpha = isReachedBottom ? 0 : 1
        }
    }
    
    func addBlurToView() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
}

extension WhatsNewMoreViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleBlurShowing(animated: true)
    }
}
