//
//  HomepageViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit

class HomepageViewController: UIViewController {
    
    var homepageTableVC: HomepageTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "embedTable" {
            homepageTableVC = segue.destination as? HomepageTableViewController
            homepageTableVC?.delegate = self
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
    }
}

extension HomepageViewController: HomepageMainDelegate {
    func navigateToOfficeStatus() {
        performSegue(withIdentifier: "showOfficeStatus", sender: nil)
    }
}
