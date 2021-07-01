//
//  MainViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTabBar", let navController = segue.destination as? UINavigationController, let tabBarController = navController.rootViewController as? UITabBarController {
            tabBarController.modalPresentationCapturesStatusBarAppearance = true
            if UserDefaults.standard.object(forKey: "productionAlertNotificationReceived") != nil, let applicationsTabIdx = self.tabBarController?.viewControllers?.firstIndex(where: { (vc: UIViewController) in
                guard let appsNavController = vc as? UINavigationController else { return false }
                return appsNavController.rootViewController is AppsViewController
            }) {
                tabBarController.selectedIndex = applicationsTabIdx
            }
        }
    }

}

extension MainViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
    }
}
