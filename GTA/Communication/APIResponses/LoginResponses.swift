//
//  LoginResponses.swift
//  GTA
//
//  Created by Margarita N. Bock on 24.11.2020.
//

import Foundation

struct AccessTokenValidationResponseData: Codable {
    var username: String
    var token: String
    var lifetime: Int
    var expireAfter: Int
    var actions: [String]
    var stickers: [String]
    
    enum CodingKeys: String, CodingKey {
        case username = "name"
        case token = "token"
        case lifetime = "lifetime"
        case expireAfter = "expire_after"
        case actions = "actions"
        case stickers = "stickers"
    }
}

struct AccessTokenValidationResponse: Codable {
    var status: ResponseMetaData
    var data: AccessTokenValidationResponseData
}
