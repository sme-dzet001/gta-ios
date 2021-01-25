//
//  TicketDetailsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit
import PanModal

class TicketDetailsViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var screenTitleView: UIView!
    @IBOutlet weak var blurView: UIView!
    
    private var heightObserver: NSKeyValueObservation?
    lazy var textView = SendMessageView.instanceFromNib()
    
    private var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
        
    var panScrollable: UIScrollView? {
        return tableView
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var shortFormHeight: PanModalHeight {
        return initialHeight
    }
    
    var allowsExtendedPanScrolling: Bool {
        return true
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
        
    var initialHeight: PanModalHeight = .maxHeight
    
    private var isFirstTime: Bool = true
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var dataSource: TicketData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurToView()
        setUpTextViewIfNeeded()
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.configureBlurViewPosition()
            self?.configurePosition()
        })
    }
    
    override func viewDidLayoutSubviews() {
        configureBlurViewPosition()
        if dataSource?.status == .open && isFirstTime {
            panModalTransition(to: .longForm)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isFirstTime = false
    }
    
    private func configureBlurViewPosition() {
        guard position > 0 else { return }
        blurView.frame.origin.y = position - blurView.frame.height
        self.view.layoutIfNeeded()
    }
        
    func addBlurToView() {
        blurView.isHidden = false
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
    private func setUpTextViewIfNeeded() {
        guard dataSource?.status == .open else { return }
        textView.setUpTextView()
        var coefficient: CGFloat = 0
        if #available(iOS 13.0, *) {
            coefficient = view.window?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
        } else {
            coefficient = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
        }
        textView.frame = CGRect(x: 24, y: self.view.frame.height - coefficient, width: self.view.frame.width - 48, height: 56)
        tableViewBottom.constant = 66
        self.view.addSubview(textView)
        textView.textView.delegate = self
        textView.sendButtonDelegate = self
    }
    
    private func configurePosition() {
        guard dataSource?.status == .open else { return }
        let coefficient: CGFloat = UIDevice.current.iPhone7_8 || UIDevice.current.iPhone5_se ? 10 : 0
        textView.frame.origin.y = position - textView.frame.height - (UIWindow.key?.safeAreaInsets.bottom ?? 0.0) - coefficient
        let subtract = self.view.frame.height - position + 66 + (UIWindow.key?.safeAreaInsets.bottom ?? 0.0) + coefficient
        tableViewBottom.constant = subtract <= 66 ? 66 : subtract
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "TicketDetailsMessageCell", bundle: nil), forCellReuseIdentifier: "TicketDetailsMessageCell")
    }

    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        panModalTransition(to: .longForm)
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            let overlay: CGFloat = keyboardSize.height
            guard keyboardSize.height > 0 else { return }
            UIView.animate(withDuration: 0.3, animations: {
                guard overlay > 0 else {return}
                self.view.frame.origin.y = -overlay
                self.view.layoutIfNeeded()
                self.screenTitleView.frame.origin.y = overlay
            })
        }
    }
    
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {
        hideKeyboard()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.screenTitleView.frame.origin.y = 0
        self.view.frame.origin.y = 0
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        heightObserver?.invalidate()
    }
    
}

extension TicketDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TicketDatailsHeader.instanceFromNib()
        header.fillHeaderLabels(with: dataSource)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 190
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.comments.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailsMessageCell", for: indexPath) as? TicketDetailsMessageCell
        cell?.fillCell(with: dataSource?.comments[indexPath.row])
        return cell ?? UITableViewCell()
    }
    
}

extension TicketDetailsViewController: UITextViewDelegate, SendButtonPressedDelegate {
    
    func sendButtonDidPressed() {
        print("message was sent")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let customTextView = textView as? CustomTextView else { return }
        customTextView.textViewDidChange()
    }
}
