//
//  ProductionAlertsResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.06.2021.
//

import Foundation

struct ProductionAlertsResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : [String : ProductionAlertsData]]?
}

struct ProductionAlertsData: Codable {
    var data: ProductionAlertsRows?
}

struct ProductionAlertsRows: Codable {
    var rows: [ProductionAlertsRow?]?
}

struct ProductionAlertsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var indexes: [String : Int] = [:]
    var ticketNumber: String? {
        guard let values = values, let index = indexes["ticket_number"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var issueReason: String? {
        guard let values = values, let index = indexes["issue_reason"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var summary: String? {
        guard let values = values, let index = indexes["summary"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var description: String? {
        guard let values = values, let index = indexes["description"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var impactedSystems: String? {
        guard let values = values, let index = indexes["impacted_systems"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var sourceJiraIssue: String? {
        guard let values = values, let index = indexes["source_jira_issue"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var lastComment: String? {
        guard let values = values, let index = indexes["last_comment"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var duration: String? {
        guard let values = values, let index = indexes["maintenance_duration"], values.count > index else { return nil }
        let duration = Float(values[index]?.stringValue ?? "") ?? 0.0
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.month, .day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: TimeInterval(duration * 3600))!
        return formattedString
    }
    var sendPush: String? {
        guard let values = values, let index = indexes["send_push"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var sendPushBeforeStartInHr: Float? {
        guard let values = values, let index = indexes["send_push_before_start_in_hr"], values.count > index else { return nil }
        return values[index]?.floatValue
    }
    private var statusString: String? {
        guard let values = values, let index = indexes["status"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var startDateString: String? {
        guard let valuesArr = values, let index = indexes["start_date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return nil }
        return dateString
    }
    var closeDateString: String? {
        guard let valuesArr = values, let index = indexes["closed_date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return nil }
        return dateString
    }
    var startDate: Date {
        guard let valuesArr = values, let index = indexes["start_date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return Date() }
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.dateFormatWithoutTimeZone
        dateFormatterPrint.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatterPrint.date(from: dateString) ?? Date()
    }
    var closeDate: Date {
        guard let valuesArr = values, let index = indexes["closed_date"], valuesArr.count > index, let dateString = valuesArr[index]?.stringValue else { return Date() }
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.dateFormatWithoutTimeZone
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
    var status: GlobalAlertStatus {
        guard let _ = statusString else { return .closed }
        switch statusString!.lowercased() {
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
    var isRead: Bool {
        if let _ = UserDefaults.standard.value(forKey: summary?.lowercased() ?? "") {
            return true
        }
        return false
    }
    
    var prodAlertsStatus: ProductionAlertsStatus {
        if status == .inProgress {
            let advancedTimeInterval = 3600 * Double(sendPushBeforeStartInHr ?? 0)
            if startDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                return .activeAlert
            } else if startDate.timeIntervalSince1970 - advancedTimeInterval >= Date().timeIntervalSince1970 {
                return .reminderState
            } else if startDate.timeIntervalSince1970 >= Date().timeIntervalSince1970 {
                return .newAlertCreated
            }
        } else if status == .closed {
            return .closed
        }
        return .none
    }
}

enum ProductionAlertsStatus: String {
    case activeAlert = "activeAlert"
    case closed = "closed"
    case reminderState = "reminderState"
    case newAlertCreated = "newAlertCreated"
    case none = "none"
}
