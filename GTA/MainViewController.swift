//
//  MainViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit
import Foundation
import WebKit

class MainViewController: UIViewController {

    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var menuButtonRightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    private var usmLogoutWebView: WKWebView!
    let menuViewController = MenuViewController()
    var backgroundView: UIView?
    //weak var tabBar: CustomTabBarController?
    var transition = CircularTransition()
    private(set) var currentScreenNavVc: UINavigationController?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return currentScreenNavVc?.topViewController?.preferredStatusBarStyle ?? .default
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.loggedOut), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.handleMenuButtonAppearance), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        usmLogoutWebView = WKWebView(frame: CGRect.zero)
        view.addSubview(usmLogoutWebView)
        usmLogoutWebView.isHidden = true
        usmLogoutWebView.navigationDelegate = self
        configureMenuButton()
        configureMenuVC()
        var row = 0
        #if HelpDeskUAT || HelpDeskDev || HelpDeskProd
        row = 1
        menuButton.isHidden = true
        #endif
        menuViewController.selectMenuItem(at: IndexPath(row: row, section: 0))
        NotificationCenter.default.addObserver(self, selector: #selector(loggedOut), name: Notification.Name(NotificationsNames.loggedOut), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMenuButtonAppearance), name: Notification.Name(NotificationsNames.handleMenuButtonAppearance), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if menuButton.cornerRadius != menuButton.frame.height / 2 {
            menuButton.cornerRadius = menuButton.frame.height / 2
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    @IBAction func menuButtonAction(_ sender: UIButton) {
        addBackground()
        //menuViewController.selectedTabIdx = tabBar?.selectedIndex
        present(menuViewController, animated: true, completion: nil)
    }
 
    private func configureMenuVC() {
        menuViewController.delegate = self
        menuViewController.chatBotDelegate = self
        menuViewController.transitioningDelegate = self
        menuViewController.modalPresentationStyle = .overCurrentContext
        menuViewController.view.frame = self.view.bounds
    }
    
    private func addBackground() {
        backgroundView = UIView(frame: UIScreen.main.bounds)
        backgroundView?.backgroundColor = .black
        backgroundView?.alpha = 0
        containerView.addSubview(backgroundView ?? UIView())
        
        UIView.animate(withDuration: 0.1, animations: {
            self.backgroundView?.alpha = 0.4
        }) { _ in
            self.view.layoutIfNeeded()
        }
    }
    
    private func clearBackground() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView?.alpha = 0
        }) { _ in
            self.backgroundView?.removeFromSuperview()
        }
    }
    
    private func configureMenuButton() {
        menuButton.layoutIfNeeded()
        menuButtonRightConstraint.constant = UIDevice.current.hasNotch ? 24 : 34
        menuButton.layer.shadowColor = UIColor.black.cgColor
        menuButton.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        menuButton.layer.masksToBounds = false
        menuButton.layer.shadowRadius = 3
        menuButton.layer.shadowOpacity = 0.3
        menuButton.layer.cornerRadius = menuButton.frame.width / 2
    }
    
    @objc private func handleMenuButtonAppearance(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String : Any] else { return }
        guard let enable = userInfo["enable"] as? Bool else { return }
        menuButton.alpha = enable ? 1 : 0
    }
    
    @objc func loggedOut() {
        currentScreenNavVc = nil
    }
    
    private func logoutAlert() {
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

extension MainViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension MainViewController: TabBarChangeIndexDelegate {
    func menuItemWasSelected(vcToSelect: UIViewController?) {
        guard let vc = vcToSelect else { return }
        setCurrentScreen(vc: vc)
    }
    
    private func setCurrentScreen(vc: UIViewController) {
        currentScreenNavVc?.willMove(toParent: nil)
        currentScreenNavVc?.view.removeFromSuperview()
        currentScreenNavVc?.removeFromParent()
        var navVC: UINavigationController
        if let nav = vc as? UINavigationController {
            let appsVC = nav.rootViewController as? AppsViewController
            appsVC?.badgeDelegate = menuViewController
            navVC = nav
        } else {
            navVC = UINavigationController(rootViewController: vc)
            navVC.isNavigationBarHidden = true
            navVC.navigationBar.tintColor = .black
        }
        navVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        currentScreenNavVc = navVC
        addChild(navVC)
        containerView.addSubview(navVC.view)
        NSLayoutConstraint.activate([
            navVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            navVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            navVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            navVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        navVC.didMove(toParent: self)
    }
    
    func moveToRootVC() {
        currentScreenNavVc?.popToRootViewController(animated: true)
    }
    
    func logoutButtonPressed() {
        DispatchQueue.main.async { [weak self] in
            self?.logoutAlert()
        }
    }
    
    func closeButtonPressed() {
        clearBackground()
    }
    
}

extension MainViewController: WKNavigationDelegate {
    
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
        DispatchQueue.main.async { [weak self] in
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
            if let sceneDelegate = self?.view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.startLoginFlow()
            }
        }
    }
}

extension MainViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = menuButton.center
        
        UIView.animate(withDuration: 0.1, animations: {
            self.menuButton.alpha = 0
        })
        
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = menuButton.center
        
        UIView.animate(withDuration: 0.1, delay: 0.2, animations: {
            self.menuButton.alpha = 1
        })
        
        return transition
    }
}

extension MainViewController: TabBarIndexChanged {
    func changeIndex(index: Int) {
        //menuViewController.selectedTabIdx = index
    }
}

extension MainViewController: ChatBotDelegate {
    func showChatBot() {
        let chatBotVC = ChatBotViewController()
        chatBotVC.modalPresentationStyle = .currentContext
        present(chatBotVC, animated: true, completion: nil)
    }
}
