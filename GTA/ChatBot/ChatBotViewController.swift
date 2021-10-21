//
//  ChatBotViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.10.2021.
//

import UIKit
import WebKit

class ChatBotViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeButton: UIButton!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    private var dataProvider: ChatBotDataProvider = ChatBotDataProvider()
    private var heightObserver: NSKeyValueObservation?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setAccessibilityIdentifiers()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpActivityIndicator()
        addErrorLabel(errorLabel)
        webView.navigationDelegate = self
        getChatBotToken()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        heightObserver?.invalidate()
        heightObserver = nil
    }
    
    private func setUpActivityIndicator() {
        self.view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.webView.center.y)
        activityIndicator.startAnimating()
    }
    
    private func getChatBotToken() {
        dataProvider.getChatBotToken {[weak self] token, errorCode, error in
            DispatchQueue.main.async {
                if errorCode == 200 && error == nil {
                    self?.setTokenAndLoadChatBot(token)
                } else {
                    self?.setErrorLabel(for: error)
                }
            }
        }
    }
    
    private func setTokenAndLoadChatBot(_ token: String?) {
        guard let _ = token, let path = Bundle.main.path(forResource: "frame", ofType: "html") else { return }
        do {
            let strHTMLContent = try String(contentsOfFile: path) as NSString
            let startRange = strHTMLContent.range(of: "token: '", options: .backwards)
            let location = startRange.location + startRange.length
            let neededRange = NSMakeRange(location, 0)
            let htmlString = strHTMLContent.replacingCharacters(in: neededRange, with: token!)
            self.webView.loadHTMLString(htmlString, baseURL: nil)
        } catch {
            self.setErrorLabel()
        }
    }
    
    private func setErrorLabel(for error: ResponseError? = nil) {
        activityIndicator.stopAnimating()
        errorLabel.text = error?.localizedDescription ?? ResponseError.commonError.localizedDescription
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
        self.setErrorLabel(for: ResponseError.generate(error: error))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    
}
