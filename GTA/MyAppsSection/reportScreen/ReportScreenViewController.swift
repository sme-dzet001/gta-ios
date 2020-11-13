//
//  ReportScreenViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.11.2020.
//

import UIKit
import PanModal

class ReportScreenViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var textView: CustomTextView!
    @IBOutlet weak var typeTextField: CustomTextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    var heightObserver: NSKeyValueObservation?
    
    private var pickerDataSource: [String] = ["Reactivate Account", "Site Down"] //temp
    var panScrollable: UIScrollView?
    weak var delegate: ShowAlertDelegate?
    private let pickerView = UIPickerView()

    var isShortFormEnabled = true
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    
    var shortFormHeight: PanModalHeight {
        if UIDevice.current.iPhone5_se {
            return .maxHeightWithTopInset(50)
        }
        return .contentHeight(height)
    }
        
    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(50)
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
        setUpTextField()
        
        setUpTextView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTextViewLayout()
        })
    }
        
    @objc private func doneAction() {
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
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doneAction))
        toolbar.setItems([doneButton, flexible, cancelButton], animated: true)
        typeTextField.inputAccessoryView = toolbar
    }
    
    private func setUpTextViewLayout() {
        let coefficient: CGFloat = UIDevice.current.iPhone5_se ? 300 : 340
        textViewHeight.constant = position - coefficient > 0 ? position - coefficient : 0
        textView.setPlaceholder()
        self.view.layoutIfNeeded()
        
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        delegate?.showAlert(title: "Issue has been submitted", message: "Wed 15 10:30 -5 GMT")
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
    
    deinit {
        heightObserver?.invalidate()
    }
    
}

extension ReportScreenViewController: UIPickerViewDelegate, UIPickerViewDataSource {

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
        typeTextField.textFieldDidChange()
    }
}

extension ReportScreenViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.textView.textViewDidChange()
    }
}
