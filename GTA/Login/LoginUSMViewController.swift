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
    
    private var dataProvider: LoginDataProvider = LoginDataProvider()
    
    private let usmBasicURL = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/authorize"
    private let usmRedirectURL = "https://gtastageapi.smedsp.com:8888/validate"
    private let usmClientID = "NVdmOTlSc2txN3ByUmozbVNQSGs"
    private let usmClientSecret = "WURSdzdjKk5tK0J3UVp3OGNZcTM"
    private let usmInternalRedirectURL = "https://gtastage.smedsp.com/charts-ui2/#/auth/processor"
    private let usmLogoutURL = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/logout"
    
    private let shortRequestTimeoutInterval: Double = 4
    
    var emailAddress = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        guard let redirectURIStr = usmRedirectURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return }
        let stateParamsDict = ["r": usmInternalRedirectURL, "n": nonceStr, "c": usmClientID];
        guard let stateData = try? JSONSerialization.data(withJSONObject: stateParamsDict, options: []) else { return }
        let stateStr = stateData.base64EncodedString()
        let authURLString = "\(usmBasicURL)?response_type=code&scope=openid&client_id=\(usmClientID)&state=\(stateStr)&nonce=\(nonceStr)&redirect_uri=\(redirectURIStr)&email=\(emailAddress)"
        if let authURL = URL(string: authURLString) {
            let authRequest = URLRequest(url: authURL, timeoutInterval: shortRequestTimeoutInterval)
            usmWebView.load(authRequest)
        }
    }
    
    private func logout() {
        guard let logoutURL = URL(string: usmLogoutURL) else { return }
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
        displayError(errorMessage: error.localizedDescription, title: "Error") { (_) in
            self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let navigationRequestURL = navigationAction.request.url else { return }
        if navigationRequestURL.absoluteString.hasPrefix(usmLogoutURL) {
            // logout was made
            KeychainManager.deleteUsername()
            KeychainManager.deleteToken()
            KeychainManager.deleteTokenExpirationDate()
            
            usmWebView.isHidden = false
            loadUsmLogon()
        }
        if navigationRequestURL.absoluteString.hasPrefix(usmRedirectURL) && navigationAction.request.timeoutInterval > shortRequestTimeoutInterval {
            let authRequest = URLRequest(url: navigationRequestURL, timeoutInterval: shortRequestTimeoutInterval)
            decisionHandler(.cancel)
            usmWebView.load(authRequest)
            return
        }
        if navigationRequestURL.absoluteString.hasPrefix(usmInternalRedirectURL) {
            guard let correctParsingFormatURL = URL(string: navigationRequestURL.absoluteString.replacingOccurrences(of: usmInternalRedirectURL, with: "https://correctparsingformat.com")) else {
                decisionHandler(.cancel)
                return
            }
            guard let aToken = Utils.valueOf(param: "access_token", forURL: correctParsingFormatURL) else {
                decisionHandler(.cancel)
                return
            }
            dataProvider.validateToken(token: aToken) { [weak self] (_ errorCode: Int, _ error: Error?) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if error == nil && errorCode == 200 {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let mainScreen = storyboard.instantiateViewController(withIdentifier: "TabBarController")
                            self.navigationController?.pushViewController(mainScreen, animated: true)
                    } else {
                        self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
                    }
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
}
