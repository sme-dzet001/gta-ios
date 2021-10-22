//
//  ChatBotDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.10.2021.
//

import Foundation

class ChatBotDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    func getChatBotToken(userMail: String, completion: ((_ token: String?, _ errorCode: Int, _ error: ResponseError?) -> Void)? = nil) {
        apiManager.getChatBotToken(userEmail: userMail) {[weak self] data, errorCode, error in
            self?.handleChatBotToken(data: data, errorCode: errorCode, error: error, completion: completion)
        }
    }
    
    private func handleChatBotToken(data: Data?, errorCode: Int, error: Error?, completion: ((_ token: String?, _ errorCode: Int, _ error: ResponseError?) -> Void)? = nil) {
        var retErr = error != nil ? ResponseError.generate(error: error) : nil
        var tokenData: TokenData? = nil
        if let _ = data {
            do {
                tokenData = try DataParser.parse(data: data!)
            } catch {
                retErr = retErr == nil ? ResponseError.parsingError : retErr
            }
            completion?(tokenData?.token, errorCode, retErr)
        } else {
            completion?(nil, 0, retErr)
        }
    }
    
}

struct TokenData: Codable {
    var conversationId: String?
    var token: String?
    var expires_in : Int?
}
