//
//  SecondTicketDetailsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit
import PanModal

class SecondTicketDetailsViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var navigationView: UIView!
    
    var messageHeaderView: SecondSendMessageView = SecondSendMessageView.instanceFromNib()
    
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
        addDetailsView()
    }
    
    private func addDetailsView() {
        let detailsView = TicketDatailsHeader.instanceFromNib()
        detailsView.fillHeaderLabels(with: dataSource)
        let sdsdd = self.headerView.frame.height + self.headerView.frame.origin.y
        detailsView.frame = CGRect(x: 0, y: sdsdd, width: self.view.frame.width, height: 190)
        view.insertSubview(detailsView, belowSubview: navigationView) //addSubview(detailsView)
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
            var overlay: CGFloat = keyboardSize.height
            if UIDevice.current.iPhone4_4s || UIDevice.current.iPhone5_se || UIDevice.current.iPhone7_8_Zoomed {
                overlay = overlay - 145
            }
            guard keyboardSize.height > 0 else { return }
            let headerRect = tableView.rectForHeader(inSection: 0)
            let rectToSuperview = tableView.convert(headerRect, to: tableView.superview)
            let difference = self.view.frame.height - (rectToSuperview.origin.y + rectToSuperview.height)
            UIView.animate(withDuration: 0.3, animations: {
                guard keyboardSize.height > difference else {return}
                self.view.frame.origin.y = -(keyboardSize.height - difference)
                self.navigationView.frame.origin.y = keyboardSize.height - difference
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
        self.navigationView.frame.origin.y = 0
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
}

extension SecondTicketDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataSource?.status == .closed {
            return nil
        }
        messageHeaderView.setUpView()
        return messageHeaderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource?.status == .closed {
            return 0
        }
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

extension SecondTicketDetailsViewController: UITextViewDelegate, SendButtonPressedDelegate {
    
    func sendButtonDidPressed() {
        print("message was sent")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let customTextView = textView as? CustomTextView else { return }
        customTextView.textViewDidChange()
    }
}
