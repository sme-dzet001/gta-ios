//
//  MainViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit
import Foundation

class MainViewController: UIViewController {

    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var backgroundView: UIView?
    var tabBar: UITabBarController?
    var selectedTabIdx = 0 {
        didSet {
            tabBar?.selectedIndex = selectedTabIdx
        }
    }
    
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
        if segue.identifier == "embedTabBar" {
            tabBar = segue.destination as? UITabBarController
        }
    }
    
    @IBAction func menuButtonAction(_ sender: UIButton) {
        showPopoverMenu()
    }
 
    private func showPopoverMenu() {
        let popoverContentController = MenuViewController()
        popoverContentController.delegate = self
        popoverContentController.selectedTabIdx = selectedTabIdx
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.preferredContentSize = CGSize(width: view.frame.width, height: 500)
        let frame = CGRect(x: menuButton.frame.maxX - 48, y: menuButton.frame.maxY, width: menuButton.frame.width, height: menuButton.frame.height)
        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = frame
            popoverPresentationController.delegate = self
            present(popoverContentController, animated: true, completion: nil)
        }
    }
}

extension MainViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
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
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView?.alpha = 0
        }) { _ in
            self.backgroundView?.removeFromSuperview()
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension MainViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension MainViewController: TabBarChangeIndexDelegate {
    func changeToIndex(index: Int) {
        selectedTabIdx = index
    }
}
