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
    
    let menuViewController = MenuViewController()
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
        menuButton.dropShadow(color: .gray, opacity: 0.5, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
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
        menuViewController.delegate = self
        menuViewController.tabBar = tabBar
        menuViewController.selectedTabIdx = selectedTabIdx
        menuViewController.modalPresentationStyle = .popover
//        let height = CGFloat(menuViewController.menuItems.count) * menuViewController.defaultCellHeight + menuViewController.lineCellHeight
        menuViewController.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 530)
        if let popoverPresentationController = menuViewController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = menuButton.frame
            popoverPresentationController.delegate = self
            present(menuViewController, animated: true, completion: nil)
        }
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
    
}

extension MainViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        addBackground()
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        clearBackground()
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
    func closeButtonPressed() {
        clearBackground()
    }
    
    func changeToIndex(index: Int) {
        selectedTabIdx = index
    }
}
