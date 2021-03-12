//
//  CollaborationResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 10.03.2021.
//

import Foundation

struct CollaborationDetailsResponse: Codable, Equatable {
    var meta: ResponseMetaData?
    var data: [String : TipsAndTricksData?]?
    var indexes: [String : Int] = [:]
    
    var isEmpty: Bool {
        if let _ = values, let _ = title, let _ = description {
            return false
        }
        return true
    }
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
    
    private var values: [QuantumValue?]? {
        return data?.first?.value?.data?.rows?.first?.values
    }
    
    var icon: String? {
        guard let valuesArr = values, let index = indexes["icon"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var title: String? {
        guard let valuesArr = values, let index = indexes["app suite"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var type: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var description: String? {
        guard let valuesArr = values, let index = indexes["description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func ==(lhs: CollaborationDetailsResponse, rhs: CollaborationDetailsResponse) -> Bool {
        return lhs.description == rhs.description && lhs.title == rhs.title //&& lhs.title == rhs.title
    }
    
}

struct CollaborationDetailsData: Codable {
    var data: CollaborationDetailsRows?
}

struct CollaborationDetailsRows: Codable {
    var rows: [CollaborationDetailsRow]?
}

struct CollaborationDetailsRow: Codable {
    var values: [QuantumValue?]?
}

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
