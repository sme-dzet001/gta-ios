//
//  LoginDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 02.12.2020.
//

import Foundation

class LoginDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    func validateToken(token: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.validateToken(token: token) { (validationResponse, errorCode, error) in
            if let validationResponse = validationResponse {
                _ = KeychainManager.saveUsername(username: validationResponse.data.username)
                _ = KeychainManager.saveToken(token: validationResponse.data.token)
                let tokenExpirationDate = Date().addingTimeInterval(TimeInterval(validationResponse.data.lifetime))
                _ = KeychainManager.saveTokenExpirationDate(tokenExpirationDate: tokenExpirationDate)
            }
            completion?(errorCode, error)
        }
    }
}
