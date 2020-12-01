//
//  ReportScreenViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.11.2020.
//

import UIKit
import PanModal

class HelpReportScreenViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var textView: CustomTextView!
    @IBOutlet weak var typeTextField: CustomTextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    private var heightObserver: NSKeyValueObservation?
    
    private var pickerDataSource: [String] = ["Reactivate Account", "Site Down"] //temp
    var panScrollable: UIScrollView?
    weak var delegate: ShowAlertDelegate?
    private let pickerView = UIPickerView()
    var screenTitle: String?
    var selectedText: String? = ""
    var isShortFormEnabled = true
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var shortFormHeight: PanModalHeight {
        if UIDevice.current.iPhone5_se {
            return .maxHeightWithTopInset(20)
        }
        return .contentHeight(height)
    }
        
    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(20)
    }
    
    private var defaultHeight: CGFloat {
        if UIDevice.current.iPhone5_se {
            return self.view.frame.height - 50
        } else if UIDevice.current.iPhone7_8 || UIDevice.current.iPhone7_8_Plus {
            return UIScreen.main.bounds.height / 1.5
        }
        return UIScreen.main.bounds.height / 2
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
        titleLabel.text = screenTitle
        //setUpTextField()
        setUpTextView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
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
        
    @objc private func doneAction() {
        selectedText = self.typeTextField.text
        self.view.endEditing(true)
    }
    
    @objc private func cancelAction() {
        let index = pickerDataSource.firstIndex(of: selectedText ?? "") ?? 0
        pickerView.selectRow(index, inComponent: 0, animated: false)
        self.typeTextField.text = selectedText
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
        toolbar.setItems([doneButton, flexible, cancelButton], animated: true)
        typeTextField.inputAccessoryView = toolbar
        typeTextField.setIconForPicker(for: self.view.frame.width)
    }
    
    private func setUpTextViewLayout(isNeedCompact: Bool = false) {
        let coefficient: CGFloat = UIDevice.current.iPhone5_se ? 300 : 340
        if isNeedCompact && UIDevice.current.iPhone5_se {
            textViewHeight.constant = 60
        } else if isNeedCompact {
            textViewHeight.constant = defaultHeight - coefficient > 0 ? defaultHeight - coefficient : 0
        } else {
            textViewHeight.constant = position - coefficient > 0 ? position - coefficient : 0
        }
        self.view.layoutIfNeeded()
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.neededDateFormat
        delegate?.showAlert(title: "Issue has been submitted", message: dateFormatterPrint.string(from: Date()))
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {
        isShortFormEnabled = false
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        panModalSetNeedsLayoutUpdate()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        panModalTransition(to: .longForm)
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            var overlay: CGFloat = keyboardSize.height
            if UIDevice.current.iPhone4_4s || UIDevice.current.iPhone5_se || UIDevice.current.iPhone7_8 {
                overlay = overlay - 145
            }
            if textView.isFirstResponder {
                setUpTextViewLayout(isNeedCompact: true)
            }
            guard keyboardSize.height > 0 else { return }
            UIView.animate(withDuration: 0.3, animations: {
                guard overlay > 0, UIDevice.current.iPhone5_se || UIDevice.current.iPhone7_8 else {return}
                self.view.frame.origin.y = -overlay
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
        setUpTextViewLayout()
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        heightObserver?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
        typeTextField.text = pickerDataSource[row]
    }
}

extension HelpReportScreenViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.textView.textViewDidChange()
    }
}
