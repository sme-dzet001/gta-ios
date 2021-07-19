//
//  AuthViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.12.2020.
//

import UIKit
import LocalAuthentication
import WebKit

class AuthViewController: UIViewController {

    @IBOutlet var pinCodeBoxes: [CustomTextField]!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var logoutBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var fieldsCenterY: NSLayoutConstraint!
    @IBOutlet weak var fieldsBottom: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottom: NSLayoutConstraint!
    @IBOutlet weak var backButtonTop: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageViewTop: NSLayoutConstraint!
    @IBOutlet weak var logoImageView: UIImageView!
    private var usmLogoutWebView: WKWebView!
    private var continueButtonY: CGFloat?
    weak var delegate: AuthentificationPassed?
    private var dataProvider: LoginDataProvider = LoginDataProvider()
    
    var isSignUp: Bool = KeychainManager.getPin() == nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        pinCodeBoxes.enumerated().forEach { (index, box) in
            box.delegate = self
            box.textContentType = .username
            box.backwardDelegate = self
            box.accessibilityIdentifier = "PinCodeScreenPinBox\(index)"
        }
        setAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        setDefaultElementsState()
        setUpScreen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.isAuthentificationScreenShown = true
        if !isSignUp {
            authenticateUser()
        }
    }
    
    @objc func willResignActive() {
        if isSignUp {
            logout()
        } else {
            hideKeyboard()
        }
    }
    
    private func setAccessibilityIdentifiers() {
        backButton.accessibilityIdentifier = "PinCodeScreenBackButton"
        continueButton.accessibilityIdentifier = "LoginScreenContinueButton"
    }
    
    private func setUpScreen() {
        fieldsCenterY.isActive = !isSignUp
        fieldsBottom.isActive = isSignUp
        logoutButton.isHidden = isSignUp
        continueButton.isHidden = !isSignUp
        backButton.isHidden = !isSignUp
        pinCodeBoxes.forEach { $0.isSecureTextEntry = !isSignUp }
        if !isSignUp {
            descriptionLabel.text = "Your pin code"
            descriptionLabel.font = UIFont(name: "SFProDisplay-Light", size: 30.0)
            descriptionLabel.textColor = .black
            descriptionLabel.textAlignment = .center
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        delegate?.isAuthentificationScreenShown = false
        hideKeyboard()
    }

    private func addWebViewIfNeeded() {
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
    }

    @IBAction func continueButtonDidPressed(_ sender: Any) {
        if getCodeFromBoxes().count < 6 {
            let alert = UIAlertController(title: "Enter pincode", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        let _ = KeychainManager.createPin(pin: getCodeFromBoxes())
        authentificatePassed()
    }
    
    @IBAction func logoutButtonDidPressed(_ sender: UIButton) {
        performLogout()
    }
    
    private func performLogout() {
        guard let accessToken = KeychainManager.getToken() else { return }
        addWebViewIfNeeded()
        let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
        guard let logoutURL = URL(string: "\(USMSettings.usmLogoutURL)?token=\(accessToken)&state=\(Utils.stateStr(nonceStr))") else { return }
        let logoutRequest = URLRequest(url: logoutURL)
        usmLogoutWebView.load(logoutRequest)
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Biometrics"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [weak self] success, authenticationError in
                self?.checkAuthentification(isSuccess: success, error: authenticationError as NSError?)
            }
        }
    }
    
    private func checkAuthentification(isSuccess: Bool, error: NSError?) {
        guard error?.code != -2 else { return }
        DispatchQueue.main.async {
            if isSuccess {
                self.authentificatePassed()
            } else {
                self.showAuthenticationFailedAlert()
            }
        }
        guard isSuccess else { return }
        dataProvider.prolongSessionLength()
    }
    
    private func showAuthenticationFailedAlert() {
        let ac = UIAlertController(title: "Authentication failed", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
    
    func startAuthenticationWithPin() {
        if KeychainManager.isPinValid(pin: getCodeFromBoxes()) {
            authentificatePassed()
            dataProvider.prolongSessionLength()
        } else {
            let ac = UIAlertController(title: "Wrong PIN", message: "Entered pin code is incorrect", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.pinCodeBoxes.forEach { (box) in
                    box.text = ""
                }
                if KeychainManager.decreaseAttemptsLeft() < 1 {
                    self.logout()
                }
            }))
            self.present(ac, animated: true)
        }
    }
    
    private func getCodeFromBoxes() -> String {
        let code = pinCodeBoxes[0].text! + pinCodeBoxes[1].text! + pinCodeBoxes[2].text! + pinCodeBoxes[3].text! + pinCodeBoxes[4].text! + pinCodeBoxes[5].text!
        return code
    }
    
    private func authentificatePassed() {
        delegate?.isAuthentificationPassed = true
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
        let navController = UINavigationController(rootViewController: mainViewController)
        navController.isNavigationBarHidden = true
        navController.isToolbarHidden = true
        self.view.window?.rootViewController = navController
        (mainViewController as? UITabBarController)?.setSelectedTabAccordingToPendingAlert()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            guard keyboardSize.height > 0 else { return }
            UIView.animate(withDuration: 0.3, animations: {
                if self.isSignUp {
                    self.handleKeyboardAppearanceForSignUp(overlay: keyboardSize.height)
                } else {
                    self.handleKeyboardAppearanceForLogin(overlay: keyboardSize.height)
                }
            })
        }
    }
    
    func handleKeyboardAppearanceForLogin(overlay: CGFloat) {
        logoutBottomConstraint.constant = overlay
        if UIDevice.current.iPhone5_se {
            self.view.frame.origin.y = -10
            logoImageViewTop.constant = 40 + -self.view.frame.origin.y
        }
        self.view.layoutIfNeeded()
    }
    
    func handleKeyboardAppearanceForSignUp(overlay: CGFloat) {
        self.view.frame.origin.y = -(overlay - 60)
        if UIScreen.main.nativeBounds.height >= 1334.0 { // greater or equal then iPhone 8
            logoImageViewTop.constant = 40 + -self.view.frame.origin.y
        } else {
            logoImageView.isHidden = true
            titleLabel.isHidden = true
        }
        backButtonTop.constant = 16 + -self.view.frame.origin.y
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
        self.logoImageViewTop.constant = 40
        self.logoutBottomConstraint.constant = 16
        backButtonTop.constant = 16
        self.logoImageView.isHidden = false
        self.titleLabel.isHidden = false
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    @IBAction func backButtonDidPressed(_ sender: Any) {
        performLogout()
    }
}

extension AuthViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logout()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logout()
    }
    
    private func logout() {
        KeychainManager.deletePushNotificationTokenSent()
        KeychainManager.deleteUsername()
        KeychainManager.deleteToken()
        KeychainManager.deleteTokenExpirationDate()
        CacheManager().clearCache()
        KeychainManager.deletePinData()
        ImageCacheManager().removeCachedData()
        UserDefaults.standard.setValue(nil, forKeyPath: Constants.sortingKey)
        UserDefaults.standard.setValue(nil, forKeyPath: Constants.filterKey)
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.startLoginFlow()
        }
    }
}

extension AuthViewController: UITextFieldDelegate, BackwardDelegate {
    
    func textFieldDidSelectDeleteButton(_ textField: UITextField) {
        if let index = pinCodeBoxes.firstIndex(of: textField as! CustomTextField) {
            if index >= 1 {
                let _ = pinCodeBoxes[index - 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let neededField = getFirstEmptyBoxIfNeeded(textField)
        if textField != neededField {
            neededField.becomeFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let index = pinCodeBoxes.firstIndex(of: textField as! CustomTextField) {
            for i in index..<pinCodeBoxes.count {
                pinCodeBoxes[i].text = ""
            }
        }
    }
    
    private func getFirstEmptyBoxIfNeeded(_ textField: UITextField) -> UITextField {
        if let index = pinCodeBoxes.firstIndex(of: textField as! CustomTextField) {
            guard pinCodeBoxes[index].text == "", index != 0 else {  return textField }
            return pinCodeBoxes.first(where: {$0.text == ""}) ?? textField
        }
        return textField
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.count > 0 {
            textField.text = string
            switch textField {
            case pinCodeBoxes[0]: let _ = pinCodeBoxes[1].becomeFirstResponder()
            case pinCodeBoxes[1]: let _ = pinCodeBoxes[2].becomeFirstResponder()
            case pinCodeBoxes[2]: let _ = pinCodeBoxes[3].becomeFirstResponder()
            case pinCodeBoxes[3]: let _ = pinCodeBoxes[4].becomeFirstResponder()
            case pinCodeBoxes[4]: let _ = pinCodeBoxes[5].becomeFirstResponder()
            case pinCodeBoxes[5]: let _ = pinCodeBoxes[5].resignFirstResponder()
                if getCodeFromBoxes().count == 6, !isSignUp {
                    startAuthenticationWithPin()
                }
            default: break
            }
            return false
        } else if string.count == 0 {
            switch textField {
            case pinCodeBoxes[0]: let _ = pinCodeBoxes[0].resignFirstResponder()
            case pinCodeBoxes[1]: let _ = pinCodeBoxes[0].becomeFirstResponder()
            case pinCodeBoxes[2]: let _ = pinCodeBoxes[1].becomeFirstResponder()
            case pinCodeBoxes[3]: let _ = pinCodeBoxes[2].becomeFirstResponder()
            case pinCodeBoxes[4]: let _ = pinCodeBoxes[3].becomeFirstResponder()
            case pinCodeBoxes[5]: let _ = pinCodeBoxes[4].becomeFirstResponder()
            default: break
            }
            textField.text = ""
            return false
        }
        
        return true
    }
    
}

protocol AuthentificationPassed: AnyObject {
    var isAuthentificationPassed: Bool? {get set}
    var isAuthentificationScreenShown: Bool? {get set}
}
