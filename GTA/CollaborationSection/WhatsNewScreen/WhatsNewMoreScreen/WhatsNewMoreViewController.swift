//
//  WhatsNewMoreViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit

class WhatsNewMoreViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var dataProvider: CollaborationDataProvider?
    var dataSource: CollaborationNewsRow?
    
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
        setLabelsText()
        if let url = dataSource?.imageUrl, !url.isEmptyOrWhitespace() {
            setImage()
        } else {
            setDefaultImage()
        }
    }
    
    private func setLabelsText() {
        let text = dataSource?.decodeBody
        if let neededFont = UIFont(name: "SFProText-Regular", size: 16) {
            let range = NSRange(text!.string.startIndex..., in: text!.string)
            text?.addAttribute(.font, value: neededFont, range: range)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 22
        text?.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, text?.length ?? 0))
        infoTextView.attributedText = text
        subtitleLabel.text = dataSource?.subHeadline
    }
    
    private func setImage() {
        startAnimation()
        dataProvider?.getAppImageData(from: dataSource?.imageUrl, completion: { (data, error) in
            if let _ = data, error == nil {
                if !(self.dataSource?.imageUrl ?? "").contains(".gif"), let image = UIImage(data: data!) {
                    self.headerImageView.setImage(image)
                } else {
                    if let gif = try? UIImage(gifData: data!) {
                        self.headerImageView.setGifImage(gif)
                        self.headerImageView.startAnimatingGif()
                    } else {
                        self.setDefaultImage()
                    }
                }
            } else {
                self.setDefaultImage()
            }
            self.stopAnimation()
        })
    }
    
    private func setDefaultImage() {
        self.headerImageView.contentMode = .scaleToFill
        self.headerImageView.image = UIImage(named: "whatsNewMorePlaceholder")
        titleLabel.text = dataSource?.headline
    }
    
    private func startAnimation() {
        titleLabel.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        titleLabel.text = dataSource?.headline
        titleLabel.isHidden = false
        activityIndicator.stopAnimating()
        
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
