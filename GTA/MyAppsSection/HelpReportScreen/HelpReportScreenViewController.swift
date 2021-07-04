//
//  ReportScreenViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.11.2020.
//

import UIKit
import PanModal

class HelpReportScreenViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var textView: CustomTextView!
    @IBOutlet weak var typeTextField: CustomTextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    private var heightObserver: NSKeyValueObservation?
    var appSupportEmail: String?
    var pickerDataSource: [String] = [] 
    var panScrollable: UIScrollView?
    weak var delegate: SendEmailDelegate?
    private let pickerView = UIPickerView()
    var screenTitle: String?
    var selectedText: String = ""
    var appName: String = ""
    var isShortFormEnabled = true
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
        if UIDevice.current.iPhone5_se {
            return .maxHeight
        }
        return .contentHeight(height)
    }
        
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    private var defaultHeight: CGFloat {
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return coefficient - (view.window?.safeAreaInsets.bottom ?? 0)
    }
    
    private var height: CGFloat {
        if UIDevice.current.iPhone5_se { return defaultHeight }
        guard position >= defaultHeight else { return defaultHeight }
        return isShortFormEnabled ? defaultHeight : position - 10
    }
    
    var cornerRadius: CGFloat {
        return 20
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addAccessibilityIdentifiers()
        titleLabel.text = screenTitle
        //setUpTextField()
        setUpTextView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTextViewLayout()
        })
        setUpTextField()
    }
        
    private func addAccessibilityIdentifiers() {
        titleLabel.accessibilityIdentifier = "HelpReportIssueTitleLabel"
        textView.accessibilityIdentifier = "HelpReportIssueCommentsTextView"
        typeTextField.accessibilityIdentifier = "HelpReportIssueSelectTypeTextField"
        submitButton.accessibilityIdentifier = "HelpReportIssueSubmitButton"
        closeButton.accessibilityIdentifier = "HelpReportIssueCloseButton"
    }
    
    @objc private func doneAction() {
        self.typeTextField.text = !selectedText.isEmpty ? selectedText : pickerDataSource.first
        self.view.frame.origin.y = 0
        setUpTextViewLayout()
        self.view.endEditing(true)
    }
    
    @objc private func cancelAction() {
        let index = pickerDataSource.firstIndex(of: self.typeTextField.text ?? "") ?? 0
        pickerView.selectRow(index, inComponent: 0, animated: false)
        selectedText = pickerDataSource[index]
        self.view.frame.origin.y = 0
        setUpTextViewLayout()
        self.view.endEditing(true)
    }
    
    private func setUpTextView() {
        textView.delegate = self
    }
    
    private func setUpTextField() {
        pickerView.delegate = self
        pickerView.dataSource = self
        typeTextField.inputView = pickerView
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        toolbar.setItems([cancelButton, flexible, doneButton], animated: true)
        typeTextField.inputAccessoryView = toolbar
        typeTextField.setIconForPicker(for: self.view.frame.width)
    }
    
    private func setUpTextViewLayout(isNeedCompact: Bool = false, keyboardHeight: CGFloat? = nil) {
        if isNeedCompact {
            let compactFormCoefficient: CGFloat = 260
            let longFormScreenHeight = view.frame.height
            let keyboardOverlayHeight = keyboardHeight ?? 0
            textViewHeight.constant = longFormScreenHeight - keyboardOverlayHeight - compactFormCoefficient > 0 ? longFormScreenHeight - keyboardOverlayHeight - compactFormCoefficient : 0
        } else {
            let coefficient: CGFloat = UIDevice.current.iPhone5_se ? 260 : 280
            textViewHeight.constant = position - coefficient > 0 ? position - coefficient : 0
        }
        self.view.layoutIfNeeded()
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        if textView.text.isEmpty || (typeTextField.text?.isEmpty ?? true) {
            //panModalTransition(to: .longForm)
            let alert = UIAlertController(title: nil, message: "Please make sure all fields are filled in", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            let screenTitle = self?.screenTitle ?? ""
            let issueType = self?.typeTextField.text ?? ""
            let appName = self?.appName ?? ""
            let subject = "\(appName) \(screenTitle): \(issueType)"
            let body = self?.textView.text ?? ""
            let recipient = self?.appSupportEmail ?? ""
            self?.delegate?.sendEmail(withTitle: subject, withText: body, to: recipient)
        })
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismissModal()
    }
    
    @objc private func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {
        isShortFormEnabled = false
        hideKeyboard()
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        panModalSetNeedsLayoutUpdate()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        panModalTransition(to: .longForm)
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            setUpTextViewLayout(isNeedCompact: true, keyboardHeight: keyboardSize.height)
        }
    }
    
    @objc func hideKeyboard() {
        let index = pickerDataSource.firstIndex(of: self.typeTextField.text ?? "") ?? 0
        pickerView.selectRow(index, inComponent: 0, animated: false)
        selectedText = pickerDataSource[index]
        self.view.frame.origin.y = 0
        setUpTextViewLayout()
        view.endEditing(true)
    }
    
    deinit {
        heightObserver?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
    }
    
}

extension HelpReportScreenViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - UIPickerView Delegate and DataSource implementation
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedText = pickerDataSource[row]
    }
}

extension HelpReportScreenViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.textView.textViewDidChange()
    }
}

extension HelpReportScreenViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }
}
