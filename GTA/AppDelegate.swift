//
//  AppDelegate.swift
//  GTA
//
//  Created by Margarita N. Bock on 05.11.2020.
//

import UIKit
import CoreData
#if !GTAAutotest
import Firebase
#endif
import UserNotifications
import PanModal

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var activeNotificationHandlers: [Int : PushNotificationHandler] = [:]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let navBarTitleFont = UIFont(name: "SFProDisplay-Medium", size: 20) {
            let navBarTitleAttributes = [NSAttributedString.Key.font: navBarTitleFont]
            UINavigationBar.appearance().titleTextAttributes = navBarTitleAttributes
        }
        #if !GTAAutotest
        FirebaseApp.configure()
        #endif
        #if GTAGSD
        return true
        #endif
        registerForPushNotifications()
        return true
    }
    
    private func topViewController(controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
    func dismissPanModalIfPresented(completion: @escaping (() -> Void)) {
        if let panModal = getTopViewController() as? PanModalPresentable {
            (panModal as? UIViewController)?.dismiss(animated: true, completion: completion)
        } else if let menuVC = getTopViewController() as? MenuViewController {
            menuVC.closeAction()
            completion()
        } else {
            completion()
        }
    }
    
    func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        var topVC: UIViewController?
        if var VC = keyWindow?.rootViewController {
            while let presentedViewController = VC.presentedViewController {
                VC = presentedViewController
            }
            topVC = topViewController(controller: VC)
        }
        return topVC
    }
    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Core Data context
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GTA")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var databaseContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
}

// MARK: - UNUserNotificationCenterDelegate (Push Notification)

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let displayedNotificationName = notification.displayedNotificationName, let responseReceivedNotificationName = notification.responseReceivedNotificationName, let userDefaultsKey = notification.userDefaultsKey {
            let notificationHandler = PushNotificationHandler(displayedNotificationName: displayedNotificationName, userResponseReceivedNotificationName: responseReceivedNotificationName, userDefaultsKey: userDefaultsKey, userDefaultsValue: notification.isEmergencyOutage ? true : notification.payloadDict)
            notificationHandler.state = .displayed
            activeNotificationHandlers[notification.hashValue] = notificationHandler
        }
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let displayedNotificationName = response.notification.displayedNotificationName, let responseReceivedNotificationName = response.notification.responseReceivedNotificationName, let userDefaultsKey = response.notification.userDefaultsKey {
            let notificationHandler = activeNotificationHandlers[response.notification.hashValue] ?? PushNotificationHandler(displayedNotificationName: displayedNotificationName, userResponseReceivedNotificationName: responseReceivedNotificationName, userDefaultsKey: userDefaultsKey, userDefaultsValue: response.notification.isEmergencyOutage ? true : response.notification.payloadDict)
            notificationHandler.state = .userResponseReceived
            activeNotificationHandlers[response.notification.hashValue] = notificationHandler
        }
        completionHandler()
    }
}

extension AppDelegate {
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
                guard granted else { return }
                self?.getNotificationSettings()
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        if KeychainManager.getPushNotificationToken() != token {
            KeychainManager.deletePushNotificationTokenSent()
        }
        
        _ = KeychainManager.savePushNotificationToken(pushNotificationToken: token)
        
        PushNotificationsManager().sendPushNotificationTokenIfNeeded()
    }
    
    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        //TODO: process error
    }
    
    func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler:
      @escaping (UIBackgroundFetchResult) -> Void
    ) {
        //TODO: process notification
    }
}
