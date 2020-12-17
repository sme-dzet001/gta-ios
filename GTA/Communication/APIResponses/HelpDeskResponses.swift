//
//  HelpDeskResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

struct HelpDeskResponse: Codable {
    var data: HelpDeskRows?//[String : [HelpDeskValues]]?
    
    private var values: [String]? {
        guard let rows = data?.rows, !rows.isEmpty else { return [] }
        return rows.first?.values //data["rows"]?.first?.values
    }
    
    var serviceDeskPhoneNumber: String? {
        guard let values = values, values.count >= 5 else { return nil }
        return convertPhoneNumber(number: values[4])
    }
    var serviceDeskEmail: String? {
        guard let values = values, values.count >= 6 else { return nil }
        return values[5]
    }
    
    var teamsChatLink: String? {
        guard let values = values, values.count >= 7 else { return nil }
        return values[6]
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
    
    var question: String? {
        guard let valuesArr = values, valuesArr.count >= 6 else { return nil }
        return valuesArr[5].stringValue
    }
    
    var answer: String? {
        guard let valuesArr = values, valuesArr.count >= 7 else { return nil }
        return valuesArr[6].stringValue
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
    
    var contactPhotoUrl: String? {
        guard let valuesArr = values, valuesArr.count >= 2 else { return nil }
        return valuesArr[1].stringValue
    }
    
    var contactName: String? {
        guard let valuesArr = values, valuesArr.count >= 3 else { return nil }
        return valuesArr[2].stringValue
    }
    
    var contactEmail: String? {
        guard let valuesArr = values, valuesArr.count >= 4 else { return nil }
        return valuesArr[3].stringValue
    }
    
    var contactBio: String? {
        guard let valuesArr = values, valuesArr.count >= 5 else { return nil }
        return valuesArr[4].stringValue
    }
}

struct TeamContactsData: Codable {
    var rows: [TeamContactsRow]?
}

struct TeamContactsResponse: Codable {
    var meta: ResponseMetaData
    var data: TeamContactsData?
}

