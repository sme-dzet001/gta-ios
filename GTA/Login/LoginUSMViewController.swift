//
//  LoginUSMViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 20.11.2020.
//

import UIKit
import WebKit

class LoginUSMViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    
    private var usmWebView: WKWebView!
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var dataProvider: LoginDataProvider = LoginDataProvider()
    
    private let shortRequestTimeoutInterval: Double = 24
    
    var emailAddress = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        
        usmWebView = WKWebView(frame: CGRect.zero)
        usmWebView.translatesAutoresizingMaskIntoConstraints = false
        usmWebView.scrollView.showsVerticalScrollIndicator = false
        usmWebView.scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(usmWebView)
        NSLayoutConstraint.activate([
            usmWebView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            usmWebView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            usmWebView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            usmWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
        usmWebView.navigationDelegate = self
        usmWebView.uiDelegate = self
        
        loadUsmLogon()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addSubview(activityIndicator)
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
    }
    
    func removeCookies() {
        let cookieStore = usmWebView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieStore.delete(cookie)
            }
        }
    }
    
    private func loadUsmLogon() {
        removeCookies()
        
        let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
        guard let redirectURIStr = USMSettings.usmRedirectURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return }
        let authURLString = "\(USMSettings.usmBasicURL)?response_type=code&scope=openid&client_id=\(USMSettings.usmClientID)&state=\(Utils.stateStr(nonceStr))&nonce=\(nonceStr)&redirect_uri=\(redirectURIStr)&email=\(emailAddress)"
        if let authURL = URL(string: authURLString) {
            let authRequest = URLRequest(url: authURL, timeoutInterval: shortRequestTimeoutInterval)
            usmWebView.load(authRequest)
        }
    }
    
    private func logout() {
        guard let accessToken = KeychainManager.getToken() else { return }
        let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
        guard let logoutURL = URL(string: "\(USMSettings.usmLogoutURL)?token=\(accessToken)&state=\(Utils.stateStr(nonceStr))") else { return }
        let logoutRequest = URLRequest(url: logoutURL)
        usmWebView.load(logoutRequest)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func backButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "unwindToLogin", sender: nil)
    }
}

extension LoginUSMViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        usmWebView.alpha = 0.5
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let theURL = navigationAction.request.url else {
           return nil
        }
        //load links in Safari
        UIApplication.shared.open(theURL, options: [:], completionHandler: nil)
        return nil
    }
}

extension LoginUSMViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard error.localizedDescription != "Frame load interrupted" else { return }
        displayError(errorMessage: "Oops, something went wrong", title: "Login Failed") { (_) in
            self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let navigationRequestURL = navigationAction.request.url else { return }
        if navigationRequestURL.absoluteString.hasPrefix(USMSettings.usmLogoutURL) {
            // logout was made
            KeychainManager.deleteUsername()
            KeychainManager.deleteToken()
            KeychainManager.deleteTokenExpirationDate()
            CacheManager().clearCache()
            ImageCacheManager().removeCachedData()
            UserDefaults.standard.set(false, forKey: "userLoggedIn")
            usmWebView.isHidden = false
            //loadUsmLogon()
        }
        if navigationRequestURL.absoluteString.hasPrefix(USMSettings.usmRedirectURL) && navigationAction.request.timeoutInterval > shortRequestTimeoutInterval {
            let authRequest = URLRequest(url: navigationRequestURL, timeoutInterval: shortRequestTimeoutInterval)
            decisionHandler(.cancel)
            usmWebView.load(authRequest)
            return
        }
        if navigationRequestURL.absoluteString.contains("app_code=1160") {
            showLoginFailedAlert(message: "Your account is not setup properly. Please, contact your administrator.", title: "Login Failed")
            decisionHandler(.cancel)
            return
        }
        if navigationRequestURL.absoluteString.contains("app_code=1267") {
            showLoginFailedAlert(message: "You don't have an account. Please, contact your administrator.", title: nil)
            decisionHandler(.cancel)
            return
        }
        if navigationRequestURL.absoluteString.hasPrefix(USMSettings.usmInternalRedirectURL) {
            guard let correctParsingFormatURL = URL(string: navigationRequestURL.absoluteString.replacingOccurrences(of: USMSettings.usmInternalRedirectURL, with: "https://correctparsingformat.com")) else {
                decisionHandler(.cancel)
                return
            }
            guard let aToken = Utils.valueOf(param: "access_token", forURL: correctParsingFormatURL) else {
                decisionHandler(.cancel)
                return
            }
            usmWebView.alpha = 0.5
            activityIndicator.startAnimating()
            dataProvider.validateToken(token: aToken, userEmail: emailAddress) { [weak self] (_ errorCode: Int, _ error: Error?) in
                DispatchQueue.main.async {
                    if error == nil && errorCode == 200 {
                        UserDefaults.standard.set(true, forKey: "userLoggedIn")
                        let authVC = AuthViewController()
                        authVC.isSignUp = true
                        if let sceneDelegate = self?.view.window?.windowScene?.delegate as? SceneDelegate {
                            authVC.delegate = sceneDelegate
                        }
                        self?.navigationController?.pushViewController(authVC, animated: true)
                    } else {
                        self?.performSegue(withIdentifier: "unwindToLogin", sender: nil)
                    }
                    self?.usmWebView.alpha = 1
                    self?.activityIndicator.stopAnimating()
                }
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString, url.contains("login") {
            usmWebView.alpha = 1
            activityIndicator.stopAnimating()
        }
    }
    
    private func showLoginFailedAlert(message: String, title: String?) {
        usmWebView.alpha = 0
        activityIndicator.stopAnimating()
        displayError(errorMessage: message, title: title) { (_) in
            self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
        }
    }
}
