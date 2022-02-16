//
//  ChatBotViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.10.2021.
//

import UIKit
import WebKit
import CryptoKit

class ChatBotViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var dataProvider: ChatBotDataProvider = ChatBotDataProvider()
    private var heightObserver: NSKeyValueObservation?
    private var canReloadWebView = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setAccessibilityIdentifiers()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        setUpActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Reachability.isConnectedToNetwork() {
            webView.navigationDelegate = self
            getChatBotToken()
        } else {
            setErrorLabel()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        heightObserver?.invalidate()
        heightObserver = nil
    }
    
    private func setUpActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    private func getChatBotToken() {
        let username = KeychainManager.getUsername() ?? ""
        let md5Username = username.MD5
        dataProvider.getChatBotToken(userMail: md5Username) {[weak self] token, errorCode, error in
            DispatchQueue.main.async {
                if errorCode == 200 && error == nil {
                    self?.setTokenAndLoadChatBot(token, md5Username)
                } else {
                    self?.setErrorLabel(for: error)
                }
            }
        }
    }
    
    private func setTokenAndLoadChatBot(_ token: String?, _ mail: String?) {
        guard let token = token, let userID = mail, let path = Bundle.main.path(forResource: "frame", ofType: "html") else { return }
        do {
            let parameters = ["token: '" : token, "userID: '" : userID]
            var htmlContent = try String(contentsOfFile: path) as NSString
            for (key, value) in parameters {
                let startRange = htmlContent.range(of: key, options: .backwards)
                let location = startRange.location + startRange.length
                let neededRange = NSMakeRange(location, 0)
                htmlContent = htmlContent.replacingCharacters(in: neededRange, with: value) as NSString
            }
            self.webView.loadHTMLString(htmlContent as String, baseURL: nil)
        } catch {
            self.setErrorLabel()
        }
    }
    
    private func setErrorLabel(for error: ResponseError? = nil) {
        let errorText = "Please verify your network connection and try again. If the error persists please try again later"
        activityIndicator.stopAnimating()
        errorLabel.text = error?.localizedDescription ?? errorText
        errorLabel.isHidden = false
    }
    
    private func setAccessibilityIdentifiers() {
        closeButton.accessibilityIdentifier = "ChatBotCloseButton"
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismissModal()
    }
    
    @objc private func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            guard keyboardSize.height > 0 else { return }
        
            let offset = CGPoint(x: webView.scrollView.contentOffset.x, y: keyboardSize.height)
            webView.scrollView.setContentOffset(offset, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
    }
}

extension ChatBotViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        if canReloadWebView {
            canReloadWebView = !canReloadWebView
            getChatBotToken()
            return
        }
        self.setErrorLabel(for: ResponseError.generate(error: error))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        let url_elements = url!.components(separatedBy: ":")
        
        if navigationAction.navigationType == .linkActivated {
            if url_elements[0] == "mailto" || url_elements[0] == "tel" {
                openCustomApp(urlScheme: "\(url_elements[0]):", additional_info: url_elements[1])
                decisionHandler(.cancel)
                return
            }
            if url_elements[0] == "https" {
                openCustomApp(urlScheme: "\(url_elements[0])://", additional_info: url_elements[1])
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func openCustomApp(urlScheme:String, additional_info:String){
        if let url = URL(string:"\(urlScheme)" + "\(additional_info)") {
            let application: UIApplication = UIApplication.shared
            if application.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
