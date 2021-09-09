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
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: GeneralDataProvider = GeneralDataProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpTableView()
        // Do any additional setup after loading the view.
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
        
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        softwareVersionLabel.text = String(format: "Version \(version) (\(build))")
        setAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataProvider.getCurrentPreferences()
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if TEST_PUSH_TOKEN
        if let pushNotificationsToken = KeychainManager.getPushNotificationToken() {
            let alert = UIAlertController(title: "Device Token", message: pushNotificationsToken, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Copy to clipboard", style: .default, handler: { (_) in
                UIPasteboard.general.string = pushNotificationsToken
            }))
            present(alert, animated: true)
        }
        #endif
    }
    
    private func setUpNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.setNavigationBarBottomShadowColor(UIColor(hex: 0xF2F2F7))
    }
    
    private func setAccessibilityIdentifiers() {
        softwareVersionLabel.accessibilityIdentifier = "GeneralScreenVersionLabel"
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "GeneralCell", bundle: nil), forCellReuseIdentifier: "GeneralCell")
    }
    
    @IBAction func onLogoutButtonTap(sender: UIButton) {
        let alert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (_) in
            if Reachability.isConnectedToNetwork() {
                self?.sendLogoutRequest()
            } else {
                self?.errorLogout()
            }
        }
        okAction.accessibilityIdentifier = "GeneralScreenAlertOKButton"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.accessibilityIdentifier = "GeneralScreenAlertCancelButton"
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
        errorLogout()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorLogout()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logout()
    }
    
    private func errorLogout() {
        UserDefaults.standard.setValue(true, forKey: Constants.isNeedLogOut)
        logout(deleteToken: false)
    }
    
    private func logout(deleteToken: Bool = true) {
        DispatchQueue.main.async {
            UserDefaults.standard.setValue(nil, forKeyPath: Constants.sortingKey)
            UserDefaults.standard.setValue(nil, forKeyPath: Constants.filterKey)
            KeychainManager.deleteUsername()
            if deleteToken {
                KeychainManager.deleteToken()
            }
            KeychainManager.deletePushNotificationTokenSent()
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

extension GeneralViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralCell", for: indexPath) as? GeneralCell
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notificationVC = NotificationSettingsViewController()
        notificationVC.dataProvider = dataProvider
        self.navigationController?.pushViewController(notificationVC, animated: true)
    }
    
}
