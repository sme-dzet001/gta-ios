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
    @IBOutlet weak var softwareVersionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
        
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        softwareVersionLabel.text = String(format: "Version \(version) (\(build))")
    }
    @IBAction func onLogoutButtonTap(sender: UIButton) {
        let alert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (_) in
//            guard let accessToken = KeychainManager.getToken() else { return }
//            let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
//            let logoutURLStr = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/logout?token=\(accessToken)&state=\(Utils.stateStr(nonceStr))"
//            if let logoutURL = URL(string: logoutURLStr) {
//                let logoutRequest = URLRequest(url: logoutURL)
//                self?.usmLogoutWebView.load(logoutRequest)
//            }
            self?.sendLogoutRequest()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    private func sendLogoutRequest() {
        guard let accessToken = KeychainManager.getToken() else { return }
        let nonceStr = String(format: "%.6f", NSDate.now.timeIntervalSince1970)
        guard let logoutURL = URL(string: "\(USMSettings.usmLogoutURL)?token=\(accessToken)&state=\(Utils.stateStr(nonceStr))") else { return }
        let logoutRequest = URLRequest(url: logoutURL)
        usmLogoutWebView.load(logoutRequest)
    }

}

extension GeneralViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        //logout()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logout()
    }
    
    private func logout() {
        DispatchQueue.main.async {
            KeychainManager.deleteUsername()
            KeychainManager.deleteToken()
            KeychainManager.deleteTokenExpirationDate()
            CacheManager().clearCache()
            KeychainManager.deletePinData()
            ImageCacheManager().removeCachedData()
            if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.startLoginFlow()
            }
        }
    }
}
