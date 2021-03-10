//
//  CollaborationResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 10.03.2021.
//

import Foundation

struct CollaborationTipsAndTricksResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : TipsAndTricksData?]?
}

struct TipsAndTricksData: Codable {
    var data: TipsAndTricksRows?
}

struct TipsAndTricksRow: Codable, QuickHelpDataProtocol {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var question: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var answer: String? {
        guard let valuesArr = values, let index = indexes["body"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
}

struct TipsAndTricksRows: Codable {
    var rows: [TipsAndTricksRow]?
}

protocol QuickHelpDataProtocol {
    var question: String? {get}
    var answer: String?{get}
}
