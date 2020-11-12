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
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var typeTextField: CustomTextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submitButtonBottom: NSLayoutConstraint!
    
    var sdsd: NSKeyValueObservation?
    
    var panScrollable: UIScrollView?
    weak var delegate: ShowAlertDelegate?
    private let pickerView = UIPickerView()
    private var defaultHeight: PanModalHeight = .contentHeight(UIScreen.main.bounds.height / 1.5)

    var isShortFormEnabled = true
    var position: CGFloat = 0.0
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(height)
    }
        
    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(50)//contentHeight(UIScreen.main.bounds.height / 2)
    }
    
    private var height: CGFloat {
        guard position >= UIScreen.main.bounds.height / 1.5 else { return UIScreen.main.bounds.height / 1.5 }
        return isShortFormEnabled ? UIScreen.main.bounds.height / 1.5 : position
    }
    
    var cornerRadius: CGFloat {
        return 20
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpButtonLayout()
        
        sdsd = self.presentationController?.presentedView?.observe(\.frame, options: [.old, .new]) {
            [weak self] (object, change) in
            if change.newValue?.origin.y != change.oldValue?.origin.y {
                self?.position = UIScreen.main.bounds.height - (change.newValue?.origin.y ?? 0.0)
                self?.setUpButtonLayout()
            }
        }
        
    }
        
    @objc private func doneAction() {
        self.view.endEditing(true)
    }
    
    private func setUpTextField() {
        pickerView.delegate = self
        pickerView.dataSource = self
        typeTextField.inputView = pickerView
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doneAction))
        toolbar.setItems([doneButton, flexible, cancelButton], animated: true)
        typeTextField.inputAccessoryView = toolbar
    }
    
    private func setUpButtonLayout() {
        self.submitButtonBottom.constant = self.view.frame.height - height + 15
        self.view.layoutIfNeeded()
    }
    
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        delegate?.showAlert(title: "Issue has been submitted", message: "Wed 15 10:30 -5 GMT")
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        position = UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
        isShortFormEnabled = false
        panModalSetNeedsLayoutUpdate()
        //setUpButtonLayout()
    }
    

}

extension ReportScreenViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - UIPickerView Delegate and DataSource implementation
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "sddsdsds"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeTextField.text = "ssdsd"
        typeTextField.textFieldDidChange()
    }
}
