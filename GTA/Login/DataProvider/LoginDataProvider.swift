//
//  LoginDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 02.12.2020.
//

import Foundation

class LoginDataProvider {
    
    private var apiManager: APIManager = APIManager()
    
    func validateToken(token: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.validateToken(token: token, completion: completion)
    }
}
