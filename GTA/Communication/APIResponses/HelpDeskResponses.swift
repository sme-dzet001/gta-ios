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
    
    private var values: [String?]? {
        guard let rows = data?.rows, !rows.isEmpty else { return [] }
        return rows.first?.values //data["rows"]?.first?.values
    }
    
    var serviceDeskDesc: String? {
        guard let values = values, let index = indexes["description"], values.count > index else { return nil }
        return values[index]
    }
    
    var serviceDeskIcon: String? {
        guard let values = values, let index = indexes["icon"], values.count > index else { return nil }
        return values[index]
    }
    
    var serviceDeskPhoneNumber: String? {
        guard let values = values, let index = indexes["service_phone"], values.count > index else { return nil }
        guard let returnedValue = values[index], !returnedValue.isEmpty else { return nil }
        return returnedValue
    }
    
    var serviceDeskEmail: String? {
        guard let values = values, let index = indexes["service_email"], values.count > index else { return nil }
        guard let returnedValue = values[index], !returnedValue.isEmpty else { return nil }
        return returnedValue
    }
    
    var teamsChatLink: String? {
        guard let values = values, let index = indexes["service_teams_channel"], values.count > index else { return nil }
        guard let returnedValue = values[index], !returnedValue.isEmpty else { return nil }
        return returnedValue
    }
    
    var hoursOfOperation: String? {
        guard let values = values, let index = indexes["hours_of_operation"], values.count > index else { return nil }
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
    var values: [String?]?
}

// MARK: - Quick Help Response

struct QuickHelpRow: Codable, Equatable, QuickHelpDataProtocol {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var question: String? {
        guard let valuesArr = values, let index = indexes["question"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var answer: String? {
        guard let valuesArr = values, let index = indexes["answer"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func == (lhs: QuickHelpRow, rhs: QuickHelpRow) -> Bool {
        return lhs.question == rhs.question && lhs.answer == rhs.answer
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

struct TeamContactsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var contactPhotoUrl: String? {
        guard let valuesArr = values, let index = indexes["profile picture"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactName: String? {
        guard let valuesArr = values, let index = indexes["name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactEmail: String? {
        guard let valuesArr = values, let index = indexes["email"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactPosition: String? {
        guard let valuesArr = values, let index = indexes["job title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactLocation: String? {
        guard let valuesArr = values, let index = indexes["location"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactBio: String? {
        guard let valuesArr = values, let index = indexes["bio"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var contactFunFact: String? {
        guard let valuesArr = values, let index = indexes["fun fact"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
}

struct TeamContactsData: Codable {
    var rows: [TeamContactsRow]?
}

struct TeamContactsResponse: Codable {
    var meta: ResponseMetaData
    var data: TeamContactsData?
}

struct GSDStatus: Codable {
    var meta: ResponseMetaData?
    var data: GSDStatusData?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case data = "data"
    }
    
    private var values: [QuantumValue?]? {
        guard let rows = data?.rows, !rows.isEmpty, let values = rows.first else { return [] }
        return values?.values //data["rows"]?.first?.values
    }
    
    var serviceDeskStatus: String? {
        guard let values = values, let index = indexes["status"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
}

struct GSDStatusData: Codable {
    var rows: [GSDStatusRow?]?
    var requestDate: String?
}

struct GSDStatusRow: Codable {
    var values: [QuantumValue?]?
}

struct GSDMyTickets: Codable {
    var meta: ResponseMetaData?
    var data: [String : GSDMyTicketsData?]?
}

struct GSDMyTicketsData: Codable {
    var data: GSDMyTicketsRows?
}

struct GSDMyTicketsRows: Codable {
    var rows: [GSDMyTicketsRow?]?
}

struct GSDMyTicketsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    var comments: [GSDTicketCommentsRow?]?
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var ticketNumber: String? {
        guard let values = values, let index = indexes["ticket number"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var requestorEmail: String? {
        guard let values = values, let index = indexes["requestor email"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var openDate: String? {
        guard let values = values, let index = indexes["open date"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var closeDate: String? {
        guard let values = values, let index = indexes["close date"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var subject: String? {
        guard let values = values, let index = indexes["subject"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var description: String? {
        guard let values = values, let index = indexes["description"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var owner: String? {
        guard let values = values, let index = indexes["owner"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var status: TicketStatus {
        guard let values = values, let index = indexes["status"], values.count > index else { return .none }
        switch values[index]?.stringValue?.lowercased() {
        case "new":
            return .new
        case "closed":
            return .closed
        case "open":
            return .open
        default:
            return .none
        }
    }
    
    static func == (lhs: GSDMyTicketsRow, rhs: GSDMyTicketsRow) -> Bool {
        return lhs.ticketNumber == rhs.ticketNumber && lhs.openDate == rhs.openDate && lhs.closeDate == rhs.closeDate && lhs.owner == rhs.owner && lhs.status == rhs.status && lhs.description == rhs.description && lhs.subject == rhs.subject
    }
    
}

struct GSDTicketCommentsResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : [String : GSDTicketCommentsData?]]?
}

struct GSDTicketCommentsData: Codable {
    var data: GSDTicketCommentsRows?
}

struct GSDTicketCommentsRows: Codable {
    var rows: [GSDTicketCommentsRow?]?
}

struct GSDTicketCommentsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    var decodedBody: NSMutableAttributedString?
    var isSenderMe: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var createdBy: String? {
        guard let values = values, let index = indexes["created by"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var ticketNumber: String? {
        guard let values = values, let index = indexes["ticket number"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var requestorEmail: String? {
        guard let values = values, let index = indexes["ticket requestor email"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    var createdDate: String? {
        guard let values = values, let index = indexes["created date"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    
    var body: String? {
        guard let values = values, let index = indexes["body"], values.count > index else { return nil }
        return values[index]?.stringValue
    }
    
    static func == (lhs: GSDTicketCommentsRow, rhs: GSDTicketCommentsRow) -> Bool {
        return lhs.ticketNumber == rhs.ticketNumber && lhs.requestorEmail == rhs.requestorEmail && lhs.body == rhs.body
    }
    
}
