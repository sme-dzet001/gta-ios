//
//  PushNotificationHandler.swift
//  GTA
//
//  Created by Margarita N. Bock on 22.03.2022.
//

import Foundation

enum PushNotificationHandlingState {
    case undefined
    case displayed
    case userResponseReceived
}

class PushNotificationHandler {
    var displayedNotificationName: Notification.Name
    var userResponseReceivedNotificationName: Notification.Name
    var userDefaultsKey: String
    var userDefaultsValue: Any?
    
    var state: PushNotificationHandlingState = .undefined {
        didSet {
            switch state {
            case .displayed:
                NotificationCenter.default.post(name: displayedNotificationName, object: nil)
            case .userResponseReceived:
                if oldValue == .displayed {
                    let payloadDict = userDefaultsValue as? [String : Any]
                    NotificationCenter.default.post(name: userResponseReceivedNotificationName, object: nil, userInfo: payloadDict)
                } else {
                    UserDefaults.standard.setValue(userDefaultsValue, forKey: userDefaultsKey)
                    UserDefaults.standard.synchronize()
                }
            default:
                break
            }
        }
    }
    
    init(displayedNotificationName: Notification.Name, userResponseReceivedNotificationName: Notification.Name, userDefaultsKey: String, userDefaultsValue: Any?) {
        self.displayedNotificationName = displayedNotificationName
        self.userResponseReceivedNotificationName = userResponseReceivedNotificationName
        self.userDefaultsKey = userDefaultsKey
        self.userDefaultsValue = userDefaultsValue
    }
}
