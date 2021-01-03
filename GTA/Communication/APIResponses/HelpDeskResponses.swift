//
//  HelpDeskResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

struct HelpDeskResponse: Codable {
    var meta: ResponseMetaData
    var data: HelpDeskRows?//[String : [HelpDeskValues]]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case data = "data"
    }
    
    private var values: [String]? {
        guard let rows = data?.rows, !rows.isEmpty else { return [] }
        return rows.first?.values //data["rows"]?.first?.values
    }
    
    var serviceDeskPhoneNumber: String? {
        guard let values = values, let index = indexes["service_phone"], values.count > index else { return nil }
        return convertPhoneNumber(number: values[index])
    }
    var serviceDeskEmail: String? {
        guard let values = values, let index = indexes["service_email"], values.count > index else { return nil }
        return values[index]
    }
    
    var teamsChatLink: String? {
        guard let values = values, let index = indexes["service_teams_channel"], values.count > index else { return nil }
        return values[index]
    }
    
    private func convertPhoneNumber(number: String) -> String {
        let codeCount = number.replacingOccurrences(of: "+", with: "").count - 10
        return number.replacingOccurrences(of: "(\\d{\(codeCount)})(\\d{3})(\\d{3})(\\d+)", with: "$1 ($2) $3-$4", options: .regularExpression, range: nil)
    }
    
}

struct HelpDeskRows: Codable {
    var rows: [HelpDeskValues]?
}

struct HelpDeskValues: Codable {
    var values: [String]?
}

// MARK: - Quick Help Response

struct QuickHelpRow: Codable {
    var values: [QuantumValue]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var question: String? {
        guard let valuesArr = values, let index = indexes["question"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var answer: String? {
        guard let valuesArr = values, let index = indexes["answer"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
}

struct QuickHelpData: Codable {
    var rows: [QuickHelpRow]?
}

struct QuickHelpResponse: Codable {
    var meta: ResponseMetaData
    var data: QuickHelpData?
}

// MARK: - Team Contacts Response

struct TeamContactsRow: Codable {
    var values: [QuantumValue]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var contactPhotoUrl: String? {
        guard let valuesArr = values, let index = indexes["profile picture"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var contactName: String? {
        guard let valuesArr = values, let index = indexes["name"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var contactEmail: String? {
        guard let valuesArr = values, let index = indexes["email"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var contactBio: String? {
        guard let valuesArr = values, let index = indexes["bio"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
}

struct TeamContactsData: Codable {
    var rows: [TeamContactsRow]?
}

struct TeamContactsResponse: Codable {
    var meta: ResponseMetaData
    var data: TeamContactsData?
}

