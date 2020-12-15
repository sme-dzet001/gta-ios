//
//  SessionExpiredHandler.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.12.2020.
//

import Foundation
import UIKit

class SessionExpiredHandler {
    
    func handleExpiredSessionIfNeeded(for data: Data?) {
        var metaData: SessionExpired?
        if let _ = data {
            metaData = try? DataParser.parse(data: data!)
        }
        
        guard let meta = metaData, meta.meta?.userMessage == "Session expired", UserDefaults.standard.bool(forKey: "userLoggedIn") else { return }
        
        KeychainManager.deleteUsername()
        KeychainManager.deleteToken()
        KeychainManager.deleteTokenExpirationDate()
        DispatchQueue.main.async {
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


