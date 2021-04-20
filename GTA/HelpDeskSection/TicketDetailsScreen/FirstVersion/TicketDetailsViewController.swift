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
    
    var dataProvider: HelpDeskDataProvider?    
    private var heightObserver: NSKeyValueObservation?
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    lazy var textView = SendMessageView.instanceFromNib()
    private var commentsLoadingError: Error?
    
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
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.width * 0.8)
        var statusBarHeight: CGFloat = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 10 : statusBarHeight - 20
        return PanModalHeight.contentHeight(UIScreen.main.bounds.height - (coefficient + statusBarHeight))
    }
    
    var allowsExtendedPanScrolling: Bool {
        return true
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    private var isFirstTime: Bool = true
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var dataSource: GSDTickets?
    
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
        //loadComments()
    }
    
//    private func loadComments() {
//        startAnimation()
//        dataProvider?.getTicketComments(ticketNumber: dataSource?.ticketNumber ?? "", completion: {[weak self] (errorCode, error, dataWasChanged) in
//            DispatchQueue.main.async {
//                self?.commentsLoadingError = error
//                self?.stopAnimation()
//                if error == nil && errorCode == 200 {
//                    if let index = self?.dataProvider?.myTickets?.firstIndex(where: {$0.ticketNumber == self?.dataSource?.ticketNumber}) {
//                        self?.dataSource?.comments = self?.dataProvider?.myTickets?[index].comments?.compactMap({$0}) ?? []
//                    }
//                    //self?.tableView.isHidden = false
//                    if dataWasChanged { self?.tableView.reloadData() }
//                } else {
//                    if self?.dataSource?.comments == nil || (self?.dataSource?.comments ?? []).isEmpty {
//                        self?.tableView.reloadData()
//                    }
//                }
//            }
//        })
//    }
    
    private func startAnimation() {
        self.commentsLoadingError = nil
        guard (dataSource?.comments ?? []).isEmpty else { return }
        self.tableView.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
        self.addLoadingIndicator(activityIndicator, isGSD: true)
    }

    private func stopAnimation() {
        self.tableView.alpha = 1
        self.activityIndicator.stopAnimating()
        self.activityIndicator.removeFromSuperview()
    }
    
    override func viewDidLayoutSubviews() {
        configureBlurViewPosition()
        if isFirstTime {
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
        //guard dataSource?.status == .new else { return }
//        textView.setUpTextView()
//        var coefficient: CGFloat = 0
//        if #available(iOS 13.0, *) {
//            coefficient = view.window?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
//        } else {
//            coefficient = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
//        }
//        textView.frame = CGRect(x: 24, y: self.view.frame.height - coefficient, width: self.view.frame.width - 48, height: 56)
//        tableViewBottom?.constant = 66
//        self.view.addSubview(textView)
//        textView.textView.delegate = self
//        textView.sendButtonDelegate = self
    }
    
    private func configurePosition() {
        //guard dataSource?.status == .new else { return }
//        let coefficient: CGFloat = UIDevice.current.iPhone7_8 || UIDevice.current.iPhone5_se ? 10 : 0
//        textView.frame.origin.y = position - textView.frame.height - (UIWindow.key?.safeAreaInsets.bottom ?? 0.0) - coefficient
//        let subtract = self.view.frame.height - position + 66 + (UIWindow.key?.safeAreaInsets.bottom ?? 0.0) + coefficient
//        tableViewBottom?.constant = subtract <= 66 ? 66 : subtract
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "TicketDetailsMessageCell", bundle: nil), forCellReuseIdentifier: "TicketDetailsMessageCell")
        tableView.register(UINib(nibName: "TicketDescriptionCell", bundle: nil), forCellReuseIdentifier: "TicketDescriptionCell")
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) {
            blurView.isHidden = true
        } else {
            blurView.isHidden = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        heightObserver?.invalidate()
    }
    
}

extension TicketDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section > 0 else { return 1 }
        if let _ = commentsLoadingError, (dataSource?.comments ?? []).isEmpty {
            return 1
        }
        return dataSource?.comments?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDescriptionCell", for: indexPath) as? TicketDescriptionCell
            cell?.setUpCell(with: dataSource)
            return cell ?? UITableViewCell()
        }
        if let _ = commentsLoadingError {
            return createErrorCell(with: (commentsLoadingError as? ResponseError)?.localizedDescription)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailsMessageCell", for: indexPath) as? TicketDetailsMessageCell
        cell?.fillCell(with: dataSource?.comments?[indexPath.row])
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
