//
//  OfficesResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 28.12.2020.
//

import Foundation

// MARK: - All Offices Response

struct OfficeRow: Codable {
    var values: [QuantumValue]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var officeId: Int? {
        guard let valuesArr = values, let index = indexes["office id"], valuesArr.count > index else { return nil }
        return valuesArr[index].intValue
    }
    
    var officeName: String? {
        guard let valuesArr = values, let index = indexes["name"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var officeLocation: String? {
        guard let valuesArr = values, let index = indexes["location"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var officeRegion: String? {
        guard let valuesArr = values, let index = indexes["region"], valuesArr.count > index else { return nil }
        return valuesArr[index].stringValue
    }
    
    var officeLatitude: Float? {
        guard let valuesArr = values, let index = indexes["gps_location_lat"], valuesArr.count > index else { return nil }
        return valuesArr[index].floatValue
    }
    
    var officeLongitude: Float? {
        guard let valuesArr = values, let index = indexes["gps_location_long"], valuesArr.count > index else { return nil }
        return valuesArr[index].floatValue
    }
}

struct AllOfficesData: Codable {
    var rows: [OfficeRow]?
}

struct AllOfficesResponse: Codable {
    var meta: ResponseMetaData
    var data: AllOfficesData?
}

// MARK: - Get/Set Office Response

struct UserPreferences: Codable {
    var officeId: String?
    
    enum CodingKeys: String, CodingKey {
        case officeId = "office_id"
    }
}

struct UserPreferencesResponseData: Codable {
    var preferences: UserPreferences?
}

struct UserPreferencesResponse: Codable {
    var status: ResponseMetaData
    var data: UserPreferencesResponseData
}
