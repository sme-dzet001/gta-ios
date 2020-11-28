//
//  GeneralViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 24.11.2020.
//

import UIKit
import WebKit

class GeneralViewController: UIViewController {
    
    private var usmLogoutWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
    }
    
    @IBAction func onLogoutButtonTap(sender: UIButton) {
        let alert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (_) in
            let logoutURLStr = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/logout"
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GeneralViewController: WKNavigationDelegate {
    
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
