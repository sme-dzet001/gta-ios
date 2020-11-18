//
//  ArticleViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.11.2020.
//

import UIKit
import PanModal

class ArticleViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var articleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    
    weak var appearanceDelegate: PanModalAppearanceDelegate?
    var articleText: String = ""
    var panScrollable: UIScrollView?
    var initialHeight: CGFloat = 0.0
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(initialHeight + 10)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        articleLabel.text = articleText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceDelegate?.panModalWillShow()
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
    
}
