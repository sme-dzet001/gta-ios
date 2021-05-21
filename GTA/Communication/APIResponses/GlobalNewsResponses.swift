//
//  GlobalNewsResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

// MARK: - News Response

struct GlobalNewsRow: Codable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var newsTitle: String? {
        guard let valuesArr = values, let index = indexes["headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var newsSubtitle: String? {
        guard let valuesArr = values, let index = indexes["sub headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var posterUrl: String? {
        guard let valuesArr = values, let index = indexes["banner"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var newsDate: String? {
        guard let valuesArr = values, let index = indexes["post date"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var newsAuthor: String? {
        guard let valuesArr = values, let index = indexes["by line"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue?.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var newsBody: String? {
        guard let valuesArr = values, let index = indexes["body"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
}

struct GlobalNewsData: Codable {
    var rows: [GlobalNewsRow?]?
}

struct GlobalNewsResponse: Codable {
    var meta: ResponseMetaData?
    var data: GlobalNewsData?
}

// MARK: - Special Alerts Response

struct SpecialAlertRow: Codable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var alertTitle: String? {
        guard let valuesArr = values, let index = indexes["alert title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var alertHeadline: String? {
        guard let valuesArr = values, let index = indexes["headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var alertSubHeadline: String? {
        guard let valuesArr = values, let index = indexes["sub headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var posterUrl: String? {
        guard let valuesArr = values, let index = indexes["banner"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var alertDate: String? {
        guard let valuesArr = values, let index = indexes["post date"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var alertAuthor: String? {
        guard let valuesArr = values, let index = indexes["by line"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue?.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var alertBody: String? {
        guard let valuesArr = values, let index = indexes["body"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
}

struct SpecialAlertsData: Codable {
    var rows: [SpecialAlertRow?]?
}

struct SpecialAlertsResponse: Codable {
    var meta: ResponseMetaData?
    var data: SpecialAlertsData?
}

enum QuantumValue: Codable, Equatable {
    
    case int(Int), string(String), float(Float), bool(Bool)
    
    init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        
        if let float = try? decoder.singleValueContainer().decode(Float.self) {
            self = .float(float)
            return
        }
        
        if let bool = try? decoder.singleValueContainer().decode(Bool.self) {
            self = .bool(bool)
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
        case .float(let value): return Int(value)
        case .bool: return nil
        }
    }
    
    var stringValue: String? {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return value
        case .float(let value): return "\(value)"
        case .bool: return nil
        }
    }
    
    var floatValue: Float? {
        switch self {
        case .int(let value): return Float(value)
        case .string(let value): return Float(value)
        case .float(let value): return value
        case .bool: return nil
        }
    }
    
    var boolValue: Bool? {
        switch self {
        case .int: return false
        case .string: return false
        case .float: return false
        case .bool(let value): return value
        }
    }
}

// MARK: - Global Alerts Response

struct GlobalAlertsResponse: Codable {
    var meta: ResponseMetaData?
    var data: GlobalAlertsData?
}

struct GlobalAlertsData: Codable, Equatable {
    var rows: [GlobalAlertRow?]?
}

struct GlobalAlertRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var ticketNumber: String? {
        guard let valuesArr = values, let index = indexes["ticket_number"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var alertTitle: String? {
        guard let valuesArr = values, let index = indexes["summary"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var description: String? {
        guard let valuesArr = values, let index = indexes["description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var sendPushFlag: String? {
        guard let valuesArr = values, let index = indexes["send_push_flag"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var endDate : String? {
        guard let valuesArr = values, let index = indexes["close date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return nil }
        return dateString.getFormattedDateStringForMyTickets()
    }
    
    var estimatedDuration : String? {
        guard let valuesArr = values, let index = indexes["estimated duration"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var jiraIssue : String? {
        guard let valuesArr = values, let index = indexes["source jira issue"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var closeComment : String? {
        guard let valuesArr = values, let index = indexes["close description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var notificationDate : String? {
        guard let valuesArr = values, let index = indexes["start date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return nil }
        return dateString.getFormattedDateStringForMyTickets()
    }
    
    var lastUpdate: Date {
        guard let valuesArr = values, let index = indexes["close date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return Date() }
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.dateFormatWithoutTimeZone
        dateFormatterPrint.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatterPrint.date(from: dateString) ?? Date()
    }
    
    var isExpired: Bool {
        let isDateExpired = (Date().timeIntervalSince1970 - lastUpdate.timeIntervalSince1970) >= 3600
        return status == .closed && isDateExpired
    }
    
    var alertStatus: String? {
        guard let valuesArr = values, let index = indexes["status"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var status: GlobalAlertStatus {
        guard let _ = alertStatus else { return .closed }
        switch alertStatus!.lowercased() {
        case "open":
            return .open
        case "closed":
            return .closed
        case "in progress":
            return .inProgress
        default:
            return .closed
        }
    }
    
}

enum GlobalAlertStatus {
    case open
    case inProgress
    case closed
}

