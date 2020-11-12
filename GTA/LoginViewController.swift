//
//  ViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        emailTextField.text = "sdsdsd@sdd.dd"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        onLoginButtonTap(sender: loginButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        hideKeyboard()
    }
    
    @IBAction func onLoginButtonTap(sender: UIButton) {
        guard let emailText = emailTextField.text, emailText.isValidEmail else {
            let alert = UIAlertController(title: "Enter a valid email address", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        performSegue(withIdentifier: "showMainScreen", sender: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            var overlay: CGFloat = keyboardSize.height
            if UIDevice.current.iPhone4_4s || UIDevice.current.iPhone5_se || UIDevice.current.iPhone7_8_Zoomed {
                overlay = overlay - 145
            }
            guard keyboardSize.height > 0 else { return }
            
            UIView.animate(withDuration: 0.3, animations: {
                guard overlay > 0 else {return}
                self.view.frame.origin.y = -overlay
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

}

