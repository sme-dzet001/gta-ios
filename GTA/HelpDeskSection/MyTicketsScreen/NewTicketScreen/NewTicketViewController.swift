//
//  NewTicketViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.04.2021.
//

import UIKit
import PanModal

class NewTicketViewController: UIViewController, PanModalPresentable {
        
    @IBOutlet weak var textView: CustomTextView!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var subjectTextField: CustomTextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    private var heightObserver: NSKeyValueObservation?
    var appUserEmail: String?
    var panScrollable: UIScrollView?
    weak var delegate: SendEmailDelegate?
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var shortFormHeight: PanModalHeight {
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return PanModalHeight.contentHeight(coefficient - (view.window?.safeAreaInsets.bottom ?? 0))
    }
        
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.labelPlaceholderTitle.text = appUserEmail
        emailTextField.trimmedPlaceholder = true
        setUpTextView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIApplication.willResignActiveNotification, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTextViewLayout()
        })
        setUpTextField()
    }
    
    private func setUpTextView() {
        textView.delegate = self
        textView.placeHolderText = "Description"
        textView.setPlaceholder()
    }
    
    private func setUpTextField() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        toolbar.setItems([doneButton], animated: true)
        subjectTextField.inputAccessoryView = toolbar
        //subjectTextField.setIconForPicker(for: self.view.frame.width)
    }
    
    private func setUpTextViewLayout(isNeedCompact: Bool = false, keyboardHeight: CGFloat? = nil) {
        if isNeedCompact {
            let compactFormCoefficient: CGFloat = 370
            let longFormScreenHeight = view.frame.height
            let keyboardOverlayHeight = keyboardHeight ?? 0
            textViewHeight.constant = longFormScreenHeight - keyboardOverlayHeight - compactFormCoefficient > 0 ? longFormScreenHeight - keyboardOverlayHeight - compactFormCoefficient : 0
        } else {
            let coefficient: CGFloat = UIDevice.current.iPhone5_se ? 370 : 390
            textViewHeight.constant = position - coefficient > 0 ? position - coefficient : 0
        }
        self.view.layoutIfNeeded()
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        if textView.text.isEmpty || (subjectTextField.text?.isEmpty ?? true) {
            //panModalTransition(to: .longForm)
            let alert = UIAlertController(title: nil, message: "Please make sure all fields are filled in", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            let issueType = self?.subjectTextField.text ?? ""
            let subject = "\(issueType)"
            let body = self?.textView.text ?? ""
            let recipient = Constants.ticketSupportEmail
            self?.delegate?.sendEmail(withTitle: subject, withText: body, to: recipient)
        })
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {
        hideKeyboard()
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        panModalSetNeedsLayoutUpdate()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        panModalTransition(to: .longForm)
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            UIView.animate(withDuration: 0.02) {
                self.setUpTextViewLayout(isNeedCompact: true, keyboardHeight: keyboardSize.height)
            }
        }
    }
    
    @objc func hideKeyboard() {
        self.view.frame.origin.y = 0
        setUpTextViewLayout()
        view.endEditing(true)
    }
    
    deinit {
        heightObserver?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
}

extension NewTicketViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.textView.textViewDidChange()
    }
}

extension NewTicketViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }
}
