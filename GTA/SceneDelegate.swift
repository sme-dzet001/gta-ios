//
//  SceneDelegate.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, AuthentificationPassed {
    
    var window: UIWindow?
    private var pinCodeWindow: UIWindow?

    var appIsInTray: Bool = false
    var appSwitcherView: UIView?
    
    var isAuthentificationPassed: Bool?
    var isAuthentificationScreenShown: Bool?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        pinCodeWindow = UIWindow(windowScene: windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        //UIApplication.shared.applicationIconBadgeNumber = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.appSwitcherView?.alpha = 0
        } completion: { [weak self] _ in
            self?.appSwitcherView?.removeFromSuperview()
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.getNotificationSettings()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        hideContent()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if !appIsInTray {
            UserDefaults.standard.setValue(nil, forKey: "lastActivityDate")
        }
        appIsInTray = false
        showNeededScreen()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        UserDefaults.standard.setValue(Date(), forKey: "lastActivityDate")
        appIsInTray = true
    }
    
    private func getTopVC() -> UIViewController? {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.getTopViewController()
        }
        return self.window?.rootViewController
    }
    
    private func showNeededScreen() {
        var tokenIsExpired = true
        if let tokenExpirationDate = KeychainManager.getTokenExpirationDate(), Date() < tokenExpirationDate {
            tokenIsExpired = false
        }
        if let _ = KeychainManager.getToken() {
            let isUserLoggedIn = UserDefaults.standard.bool(forKey: "userLoggedIn")
            if tokenIsExpired || !isUserLoggedIn {
                if UserDefaults.standard.value(forKey: "lastActivityDate") == nil {
                    removeAllData(delete: true)
                }
                if !isUserLoggedIn {
                    tokenIsExpired = false
                }
                startLoginFlow(sessionExpired: tokenIsExpired)
            } else {
                var lastActivityDate = Date.distantPast
                if let aDate = UserDefaults.standard.value(forKey: "lastActivityDate") as? Date {
                    lastActivityDate = aDate
                }
                if lastActivityDate.addingTimeInterval(1200) > Date(),  let _ = KeychainManager.getPin(), !(isAuthentificationScreenShown ?? true), isAuthentificationPassed ?? false {
                    if let navController = self.window?.rootViewController as? UINavigationController, navController.rootViewController is MainViewController {
                        return
                    }
                    setUpMainWindow()
                    return
                } else if KeychainManager.getPin() == nil {
                    let authScreenShown = isAuthentificationScreenShown ?? false
                    if !authScreenShown {
                        return
                    }
                    removeAllData(delete: UserDefaults.standard.bool(forKey: Constants.isNeedLogOut))
                    startLoginFlow(sessionExpired: tokenIsExpired)
                    return
                }
                showAuthScreen()
            }
        } else if getTopVC() is LoginUSMViewController {
            return
        } else {
            startLoginFlow()
        }
    }
    
    private func showAuthScreen() {
        setUpMainWindow()
        let authVC = AuthViewController()
        authVC.isSignUp = false
        authVC.appKeyWindow = window
        authVC.delegate = self
        pinCodeWindow?.frame = UIScreen.main.bounds
        pinCodeWindow?.windowLevel = UIWindow.Level.statusBar + 1
        pinCodeWindow?.rootViewController = authVC
        pinCodeWindow?.makeKeyAndVisible()
    }
    
    private func setUpMainWindow() {
        let windowController = window?.rootViewController as? UINavigationController
        guard let _ = windowController, windowController!.rootViewController is LoginViewController else { return }
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyBoard.instantiateViewController(withIdentifier: "MainViewController")
        let navController = UINavigationController(rootViewController: mainViewController)
        navController.isNavigationBarHidden = true
        navController.isToolbarHidden = true
        self.window?.rootViewController = navController
    }
    
    private func removeAllData(delete: Bool = true) {
        KeychainManager.deletePushNotificationTokenSent()
        KeychainManager.deleteUsername()
        if delete {
            KeychainManager.deleteToken()
        }
        KeychainManager.deleteTokenExpirationDate()
        KeychainManager.deletePinData()
        CacheManager().clearCache()
        UserDefaults.standard.removeObject(forKey: "NumberOfNews")
    }

    func startLoginFlow(sessionExpired: Bool = false) {
        NotificationCenter.default.post(name: Notification.Name(NotificationsNames.loggedOut), object: nil)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(false, forKey: "userLoggedIn")
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            UserDefaults.standard.setValue(nil, forKeyPath: Constants.sortingKey)
            UserDefaults.standard.setValue(nil, forKeyPath: Constants.filterKey)
            loginViewController.sessionExpired = sessionExpired
            let navController = UINavigationController(rootViewController: loginViewController as UIViewController)
            navController.isNavigationBarHidden = true
            navController.isToolbarHidden = true
            self.window?.windowLevel = UIWindow.Level.statusBar + 1
            self.window?.rootViewController = navController
            self.window?.makeKeyAndVisible()
        }
    }
    
    func hideContent() {
        if let navController = window?.rootViewController as? UINavigationController, navController.rootViewController is MainViewController {
            appSwitcherView = UIView()
            appSwitcherView?.frame = self.window!.bounds
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //blurEffectView.alpha = 0.99
            blurEffectView.frame = window!.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if let _ = appSwitcherView {
                appSwitcherView?.alpha = 0
                appSwitcherView?.addSubview(blurEffectView)
                self.window?.addSubview(self.appSwitcherView!)
                UIView.animate(withDuration: 0.3) {
                    self.appSwitcherView?.alpha = 1
                }
            }
        }
    }
    
}

