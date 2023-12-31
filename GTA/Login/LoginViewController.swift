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
    @IBOutlet weak var logoImageTop: NSLayoutConstraint!
    @IBOutlet weak var loginTitleBottom: NSLayoutConstraint!
    
    var sessionExpired = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        if let lastUserEmail = UserDefaults.standard.string(forKey: "lastUserEmail") {
            emailTextField.text = lastUserEmail
            emailTextField.textFieldDidChange(makePlaceHolderSmall: true, animate: false)
        }
        setAccessibilityIdentifiers()
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
    
    private func setAccessibilityIdentifiers() {
        emailTextField.accessibilityIdentifier = "LoginScreenLoginTextField"
        loginButton.accessibilityIdentifier = "LoginScreenLoginButton"
    }
    
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) {
    }
    
    @IBAction func onLoginButtonTap(sender: UIButton) {
        let emailText = String(emailTextField.text?.split(separator: " ").first ?? "")
        guard emailText.isValidEmail else {
            showAlert(title: "Enter a valid email address", message: "")
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let usmLoginScreen = storyboard.instantiateViewController(withIdentifier: "LoginUSMViewController") as? LoginUSMViewController {
            usmLoginScreen.emailAddress = emailText
            #if GTAAutotest
            let token = String(emailTextField.text?.split(separator: " ").last ?? "")
            usmLoginScreen.token = token != emailText ? token : ""
            #endif
            usmLoginScreen.showErrorAlertDelegate = self
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
    
    func handleKeyboardAppearance(overlay: CGFloat) {
        let yPointLoginBtn = self.view.frame.height - (loginButton.frame.origin.y + loginButton.frame.height)
        let yPointLoginBtnWithOffset = yPointLoginBtn - 20
        if overlay > yPointLoginBtnWithOffset {
            self.view.frame.origin.y = yPointLoginBtnWithOffset - overlay
            if UIScreen.main.nativeBounds.height >= 1334.0 { // greater or equal then iPhone 8
                logoImageTop.constant = 10 + -self.view.frame.origin.y
                loginTitleBottom.constant = 40
            } else {
                logoImageView.isHidden = true
                titleLabel.isHidden = true
            }
        }
        self.view.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: {
            self.setDefaultElementsState()
            self.view.layoutIfNeeded()
        })
    }
    
    func setDefaultElementsState() {
        self.view.frame.origin.y = 0
        self.logoImageTop.constant = 10
        self.loginTitleBottom.constant = 40
        self.logoImageView.isHidden = false
        self.titleLabel.isHidden = false
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

}

extension LoginViewController: ShowErrorAlertDelegate {
    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

extension LoginViewController: LoginSaverDelegate {
    func saveLoginMail() {
        let emailText = String(emailTextField.text?.split(separator: " ").first ?? "")
        UserDefaults.standard.setValue(emailText, forKey: "lastUserEmail")
        
    }
}

