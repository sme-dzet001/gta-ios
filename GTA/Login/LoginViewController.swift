//
//  ViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var forgotPasswordBottom: NSLayoutConstraint!
    
    private let defaultForgotPasswordBottom: CGFloat = 16
    var sessionExpired = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        emailTextField.text = "kostiantyn.dzetsiuk.intimetechnologies@sonymusic.com"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
        setDefaultElementsState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if sessionExpired {
            showSessionExpiredAlert()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        hideKeyboard()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) {
    }
    
    @IBAction func onLoginButtonTap(sender: UIButton) {
        guard let emailText = emailTextField.text, emailText.isValidEmail else {
            let alert = UIAlertController(title: "Enter a valid email address", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let usmLoginScreen = storyboard.instantiateViewController(withIdentifier: "LoginUSMViewController") as? LoginUSMViewController {
            usmLoginScreen.emailAddress = emailText
            self.navigationController?.pushViewController(usmLoginScreen, animated: true)
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            guard keyboardSize.height > 0 else { return }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.handleKeyboardAppearance(overlay: keyboardSize.height)
            })
        }
    }
    
    private func showSessionExpiredAlert() {
        let title = "Your session has expired"
        displayError(errorMessage: "", title: title) { [weak self] (UIAlertAction) in
            self?.sessionExpired = false
        }
    }
    
    private func handleKeyboardAppearance(overlay: CGFloat) {
        let yPointLoginBtn = self.view.frame.height - (loginButton.frame.origin.y + loginButton.frame.height)
        forgotPasswordBottom.constant = yPointLoginBtn - self.forgotPasswordButton.frame.height - 10 - self.view.safeAreaInsets.bottom - 20
        if overlay > forgotPasswordBottom.constant {
            self.view.frame.origin.y = forgotPasswordBottom.constant - (overlay + 20)
            logoImageView.isHidden = true
            titleLabel.isHidden = true
            loginLabel.isHidden = UIDevice.current.iPhone5_se
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
        setDefaultElementsState()
    }
    
    private func setDefaultElementsState() {
        forgotPasswordBottom.constant = defaultForgotPasswordBottom
        logoImageView.isHidden = false
        titleLabel.isHidden = false
        loginLabel.isHidden = false
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

}

