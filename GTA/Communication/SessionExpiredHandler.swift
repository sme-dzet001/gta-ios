//
//  SessionExpiredHandler.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.12.2020.
//

import Foundation
import UIKit

class SessionExpiredHandler: ExpiredSessionDelegate {
    
    func handleExpiredSessionIfNeeded(for data: Data?) {
        var metaData: SessionExpired?
        if let _ = data {
            metaData = try? DataParser.parse(data: data!)
        }
        guard let userMessage = metaData?.meta?.userMessage, (userMessage == "Session expired" || userMessage == "Authorization error"), let _ = KeychainManager.getToken() else { return }
        print("Session expired \(userMessage)")
        UserDefaults.standard.setValue(true, forKey: Constants.isNeedLogOut)
        removeAllData()
    }
    
    private func removeAllData() {
        KeychainManager.deleteUsername()
        //KeychainManager.deleteToken()
        KeychainManager.deleteTokenExpirationDate()
        KeychainManager.deletePinData()
        KeychainManager.deletePushNotificationTokenSent()
        ImageCacheManager().removeCachedData()
        UserDefaults.standard.setValue(nil, forKeyPath: Constants.sortingKey)
        UserDefaults.standard.setValue(nil, forKeyPath: Constants.filterKey)
        DispatchQueue.main.async {
            CacheManager().clearCache()
            if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                delegate.startLoginFlow(sessionExpired: true)
            }
        }
    }
    
}

struct SessionExpired: Codable {
    var meta: ResponseMetaData?
    
    enum CodingKeys: String, CodingKey {
        case meta
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meta = (try? container.decode(ResponseMetaData.self, forKey: .meta) )
    }
}

protocol ExpiredSessionDelegate: AnyObject {
    func handleExpiredSessionIfNeeded(for data: Data?)
}
