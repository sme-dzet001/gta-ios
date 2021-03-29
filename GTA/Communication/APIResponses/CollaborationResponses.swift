//
//  CollaborationResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 10.03.2021.
//

import Foundation

struct CollaborationDetailsResponse: Codable, Equatable {
    var meta: ResponseMetaData?
    var data: [String : CollaborationDetailsData?]?
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
    
    var groupName: String? {
        guard let valuesArr = values, let index = indexes["group name"], valuesArr.count > index else { return nil }
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

struct TipsAndTricksRow: Codable, QuickHelpDataProtocol, Equatable {
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


struct CollaborationAppDetailsResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : CollaborationAppDetailsData?]?
}

struct CollaborationAppDetailsData: Codable {
    var data: CollaborationAppDetailsRows?
}

struct CollaborationAppDetailsRows: Codable, Equatable {
    var rows: [CollaborationAppDetailsRow]?
    
}

struct CollaborationAppDetailsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    
    var indexes: [String : Int] = [:]
    var imageData: Data?
    var imageStatus: LoadingStatus = .loading
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var appSupportEmail: String? {
        guard let valuesArr = values, let index = indexes["app support email"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var description: String? {
        guard let valuesArr = values, let index = indexes["description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportPhone: String? {
        guard let valuesArr = values, let index = indexes["app support phone"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appWikiUrl: String? {
        guard let valuesArr = values, let index = indexes["app wiki url"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var icon: String? {
        guard let valuesArr = values, let index = indexes["icon"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var title: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportUrl: String? {
        guard let valuesArr = values, let index = indexes["app support url"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appName: String? {
        guard let valuesArr = values, let index = indexes["app name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSuite: String? {
        guard let valuesArr = values, let index = indexes["app suite"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportPolicy: String? {
        guard let valuesArr = values, let index = indexes["app support policy"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appNameFull: String? {
        guard let valuesArr = values, let index = indexes["app name full"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func ==(lhs: CollaborationAppDetailsRow, rhs: CollaborationAppDetailsRow) -> Bool {
        return lhs.description == rhs.description && lhs.title == rhs.title && lhs.appSupportUrl == rhs.appSupportUrl && lhs.appSupportPolicy == rhs.appSupportPolicy && lhs.appWikiUrl == rhs.appWikiUrl
    }
    
}
