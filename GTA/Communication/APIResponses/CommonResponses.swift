//
//  CommonResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

struct ResponseMetaData: Codable {
    var responseCode: Int
    var userInstructions: String?
    var userMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "code"
        case userInstructions = "user_instructions"
        case userMessage = "user_message"
    }
}
