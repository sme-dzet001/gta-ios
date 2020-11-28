//
//  GlobalNewsResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

// MARK: - Report Response

struct SectionWidget: Codable {
    var generationNumber: Int
    var widgetId: String
    
    enum CodingKeys: String, CodingKey {
        case generationNumber = "generation"
        case widgetId = "widget_id"
    }
}

struct ReportSection: Codable {
    var title: String
    var sectionId: String
    var id: String
    var widgets: [SectionWidget]?
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case sectionId = "section_id"
        case id = "_id"
        case widgets = "widgets"
    }
}

struct ReportDataResponse: Codable {
    var meta: ResponseMetaData
    var data: [ReportSection]?
}

// MARK: - News Response

enum QuantumValue: Codable {
    
    case int(Int), string(String)
    
    init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        
        throw QuantumError.missingValue
    }
    
    func encode(to encoder: Encoder) throws {
        fatalError("QuantumValue encode is not implemented!")
    }
    
    enum QuantumError:Error {
        case missingValue
    }
    
    var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .string(let value): return Int(value)
        }
    }
    
    var stringValue: String? {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return value
        }
    }
}

struct GlobalNewsRow: Codable {
    var values: [QuantumValue]?
    
    // maybe add here properties by index in array
}

struct GlobalNewsData: Codable {
    var rows: [GlobalNewsRow]?
}

struct GlobalNewsResponse: Codable {
    var meta: ResponseMetaData
    var data: GlobalNewsData?
}

// MARK: - Special Alerts Response

struct SpecialAlertRow: Codable {
    var values: [QuantumValue]?
    
    // maybe add here properties by index in array
}

struct SpecialAlertsData: Codable {
    var rows: [SpecialAlertRow]?
}

struct SpecialAlertsResponse: Codable {
    var meta: ResponseMetaData
    var data: SpecialAlertsData?
}
