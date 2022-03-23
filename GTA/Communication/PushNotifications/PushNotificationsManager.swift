//
//  PushNotificationsManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 19.05.2021.
//

import Foundation

struct PushNotificationsResponse: Codable {
    var data: Bool
}

class PushNotificationsManager {
    
    func sendPushNotificationTokenIfNeeded() {
        var tokenIsExpired = true
        var isUserLoggedIn = false
        
        if let tokenExpirationDate = KeychainManager.getTokenExpirationDate(), Date() < tokenExpirationDate {
            tokenIsExpired = false
        }
        if let _ = KeychainManager.getToken() {
            isUserLoggedIn = UserDefaults.standard.bool(forKey: "userLoggedIn")
        }
        
        if !KeychainManager.isPushNotificationTokenSent() && isUserLoggedIn && !tokenIsExpired {
            let apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
            apiManager.sendPushNotificationsToken() { (response, errorCode, error) in
                if let resp = response, errorCode == 200, error == nil {
                    guard let decodedResponse = try? JSONDecoder().decode(PushNotificationsResponse.self, from: resp) else { return }
                    if decodedResponse.data {
                        _ = KeychainManager.savePushNotificationTokenSent()
                    }
                }
            }
        }
    }
    
}
