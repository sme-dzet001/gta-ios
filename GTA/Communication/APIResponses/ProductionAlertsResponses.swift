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

struct ProductionAlertsRow: Codable {
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
    var sendPush: String? {
        guard let values = values, let index = indexes["send_push"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    var sendPushBeforeStartInHr: String? {
        guard let values = values, let index = indexes["send_push_before_start_in_hr"], values.count > index else { return nil }
        return values[index]?.stringValue
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
        let isDateExpired = (Date().timeIntervalSince1970 - closeDate.timeIntervalSince1970) >= 3600
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
}
