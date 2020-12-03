//
//  HelpDeskDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

class HelpDeskDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    func getServiceDeskData(completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getServiceDeskData(completion: completion)
    }
    
}
