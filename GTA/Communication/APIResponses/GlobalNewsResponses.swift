//
//  GlobalNewsResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

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
    
    var startDate: Date {
        guard let valuesArr = values, let index = indexes["start date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return Date() }
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.dateFormatWithoutTimeZone
        dateFormatterPrint.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterPrint.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatterPrint.date(from: dateString) ?? Date()
    }
    
    var closeDate: Date {
        guard let valuesArr = values, let index = indexes["close date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return Date() }
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.dateFormatWithoutTimeZone
        dateFormatterPrint.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterPrint.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatterPrint.date(from: dateString) ?? Date()
    }
    
    var isExpired: Bool {
        #if GTADev
        let isDateExpired = (Date().timeIntervalSince1970 - closeDate.timeIntervalSince1970) >= 600
        #else
        let isDateExpired = (Date().timeIntervalSince1970 - closeDate.timeIntervalSince1970) >= 3600
        #endif
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

// MARK: - News Feed Response

struct NewsFeedResponse: Codable {
    var meta: ResponseMetaData?
    var data: NewsFeedData?
}

struct NewsFeedData: Codable, Equatable {
    var rows: [NewsFeedRow?]?
}

struct NewsContentData: Codable, Equatable {
    var body: String?
    var type: String?
}

struct NewsFeedRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var category: NewsFeedCategory {
        switch categoryStringValue.lowercased() {
        case "news":
            return .news
        case "special alerts":
            return .specialAlerts
        default:
            return .none
        }
    }
    
    private var categoryStringValue: String {
        guard let valuesArr = values, let index = indexes["category"], valuesArr.count > index else { return "" }
        return valuesArr[index]?.stringValue ?? ""
    }
    
    var articleId: Int? {
        guard let valuesArr = values, let index = indexes["article id"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.intValue
    }
    
    var headline: String? {
        guard let valuesArr = values, let index = indexes["headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var subHeadline: String? {
        guard let valuesArr = values, let index = indexes["sub headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var imagePath: String? {
        guard let valuesArr = values, let index = indexes["banner"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var postDate: String? {
        guard let valuesArr = values, let index = indexes["post date"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var newsDate: Date? {
        guard let dateString = postDate else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String.dateFormatWithoutTimeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        var date: Date? = nil
        if let formattedDate = dateFormatter.date(from: dateString) {
            date = formattedDate
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let formattedDate = dateFormatter.date(from: dateString) {
                date = formattedDate
            }
        }
        return date
    }
    
    var byLine: String? {
        guard let valuesArr = values, let index = indexes["by line"], valuesArr.count > index else { return nil }
        let byLine = valuesArr[index]?.stringValue?.replacingOccurrences(of: "\\n", with: "\n")
        return byLine
    }
    
    var newsContent: [NewsContentData]? {
        guard let valuesArr = values, let index = indexes["content"], valuesArr.count > index else { return nil }
        guard let jsonData = valuesArr[index]?.stringValue?.data(using: .utf8) else { return nil }
        do {
            return try DataParser.parse(data: jsonData)
        } catch {
            
            return nil
        }
    }
    
    var isPostDateExist: Bool {
        guard let _ = newsDate else { return false }
        return true
    }
    
}

enum NewsFeedCategory {
    case news
    case specialAlerts
    case none
}
