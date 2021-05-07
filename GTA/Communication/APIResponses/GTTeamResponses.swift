//
//  GTTeamResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 07.05.2021.
//

import Foundation

struct GTTeamResponse: Codable, Equatable {
    var meta: ResponseMetaData?
    var data: GTTeamData?
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
    
    var contactsData: [ContactData]? {
        guard let contactRows = data?.rows else { return nil }
        var res = contactRows.map({ (appContact) -> ContactData in
            guard let _ = appContact?.values else { return ContactData() }
            let appContactEmail = appContact?.email
            let appContactName = appContact?.name
            let appContactTitle = appContact?.jobTitle
            let appContactPhotoUrl = appContact?.picture
            let appContactLocation = appContact?.location
            let appContactBio = appContact?.bio
            let appContactFunFact = appContact?.funFact
            return ContactData(contactPhotoUrl: appContactPhotoUrl, contactName: appContactName, contactEmail: appContactEmail, contactPosition: appContactTitle, contactLocation: appContactLocation, contactBio: appContactBio, contactFunFact: appContactFunFact)
        })
        res.removeAll(where: {$0.contactName == nil || ($0.contactName ?? "").isEmpty || $0.contactEmail == nil || ($0.contactEmail ?? "").isEmpty})
        return res
    }
    
    static func == (lhs: GTTeamResponse, rhs: GTTeamResponse) -> Bool {
        return lhs.data == rhs.data
    }
}

struct GTTeamData: Codable, Equatable {
    var rows: [TeamRow?]?
}

struct TeamRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var picture: String? {
        guard let valuesArr = values, let index = indexes["profile picture"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var name: String? {
        guard let valuesArr = values, let index = indexes["name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var email: String? {
        guard let valuesArr = values, let index = indexes["email"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var jobTitle: String? {
        guard let valuesArr = values, let index = indexes["job title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var location: String? {
        guard let valuesArr = values, let index = indexes["location"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var bio: String? {
        guard let valuesArr = values, let index = indexes["bio"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var funFact: String? {
        guard let valuesArr = values, let index = indexes["fun fact"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func == (lhs: TeamRow, rhs: TeamRow) -> Bool {
        return lhs.picture == rhs.picture && lhs.name == rhs.name && lhs.email == rhs.email && lhs.jobTitle == rhs.jobTitle && lhs.location == rhs.location && lhs.bio == rhs.bio && lhs.funFact == rhs.funFact
    }

}
