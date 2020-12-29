//
//  LoginDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 02.12.2020.
//

import Foundation

class LoginDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    func validateToken(token: String, userEmail: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.validateToken(token: token) { (data, errorCode, error) in
            var tokenValidationResponse: AccessTokenValidationResponse?
            var retErr = error
            if let responseData = data {
                do {
                    tokenValidationResponse = try DataParser.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            if let validationResponse = tokenValidationResponse {
                _ = KeychainManager.saveUsername(username: userEmail.lowercased())
                _ = KeychainManager.saveToken(token: validationResponse.data.token)
                let tokenExpirationDate = Date().addingTimeInterval(TimeInterval(validationResponse.data.lifetime))
                _ = KeychainManager.saveTokenExpirationDate(tokenExpirationDate: tokenExpirationDate)
            }
            completion?(errorCode, retErr)
        }
    }
}
