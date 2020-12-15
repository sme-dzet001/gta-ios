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

    private var usmLogoutWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authenticateUser()
    }

    private func addWebViewIfNeeded() {
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
    }
    
    @IBAction func logoutButtonDidPressed(_ sender: UIButton) {
        addWebViewIfNeeded()
        let alert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (_) in
            guard let accessToken = KeychainManager.getToken() else { return }
            let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
            let logoutURLStr = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/logout?token=\(accessToken)&state=\(Utils.stateStr(nonceStr))"
            if let logoutURL = URL(string: logoutURLStr) {
                let logoutRequest = URLRequest(url: logoutURL)
                self?.usmLogoutWebView.load(logoutRequest)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
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
                let ac = UIAlertController(title: "Authentication failed", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        }
    }
    
    private func authentificatePassed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
        let navController = UINavigationController(rootViewController: mainViewController)
        navController.isNavigationBarHidden = true
        navController.isToolbarHidden = true
        self.view.window?.rootViewController = navController
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
        KeychainManager.deleteUsername()
        KeychainManager.deleteToken()
        KeychainManager.deleteTokenExpirationDate()
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.startLoginFlow()
        }
    }
}
