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
    var actions: [String]
    var stickers: [String]
    
    enum CodingKeys: String, CodingKey {
        case username = "name"
        case token = "token"
        case actions = "actions"
        case stickers = "stickers"
    }
}

struct AccessTokenValidationResponse: Codable {
    var data: AccessTokenValidationResponseData
}
