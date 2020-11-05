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

}

