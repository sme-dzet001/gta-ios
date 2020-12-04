//
//  GlobalNewsResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

// MARK: - News Response

struct GlobalNewsRow: Codable {
    var values: [QuantumValue]?
    
    var newsTitle: String? {
        guard let valuesArr = values, valuesArr.count >= 2 else { return nil }
        return valuesArr[1].stringValue
    }
    
    var newsSubtitle: String? {
        guard let valuesArr = values, valuesArr.count >= 3 else { return nil }
        return valuesArr[2].stringValue
    }
    
    var posterUrl: String? {
        guard let valuesArr = values, valuesArr.count >= 4 else { return nil }
        return valuesArr[3].stringValue
    }
    
    var newsDate: String? {
        guard let valuesArr = values, valuesArr.count >= 5 else { return nil }
        return valuesArr[4].stringValue
    }
    
    var newsAuthor: String? {
        guard let valuesArr = values, valuesArr.count >= 6 else { return nil }
        return valuesArr[5].stringValue
    }
    
    var newsBody: String? {
        guard let valuesArr = values, valuesArr.count >= 7 else { return nil }
        return valuesArr[6].stringValue
    }
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
    
    var alertHeadline: String? {
        guard let valuesArr = values, valuesArr.count >= 2 else { return nil }
        return valuesArr[1].stringValue
    }
    
    var alertSubHeadline: String? {
        guard let valuesArr = values, valuesArr.count >= 3 else { return nil }
        return valuesArr[2].stringValue
    }
    
    var posterUrl: String? {
        guard let valuesArr = values, valuesArr.count >= 4 else { return nil }
        return valuesArr[3].stringValue
    }
    
    var alertDate: String? {
        guard let valuesArr = values, valuesArr.count >= 5 else { return nil }
        return valuesArr[4].stringValue
    }
    
    var alertAuthor: String? {
        guard let valuesArr = values, valuesArr.count >= 6 else { return nil }
        return valuesArr[5].stringValue
    }
    
    var alertBody: String? {
        guard let valuesArr = values, valuesArr.count >= 7 else { return nil }
        return valuesArr[6].stringValue
    }
}

struct SpecialAlertsData: Codable {
    var rows: [SpecialAlertRow]?
}

struct SpecialAlertsResponse: Codable {
    var meta: ResponseMetaData
    var data: SpecialAlertsData?
}

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
