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
        return values[4]
    }
    var serviceDeskEmail: String? {
        guard let values = values, values.count >= 6 else { return nil }
        return values[5]
    }
    
    var teamsChatLink: String? {
        guard let values = values, values.count >= 7 else { return nil }
        return values[6]
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


