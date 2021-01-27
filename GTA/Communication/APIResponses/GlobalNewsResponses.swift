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
    var rows: [GlobalNewsRow]?
}

struct GlobalNewsResponse: Codable {
    var meta: ResponseMetaData
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
    var rows: [SpecialAlertRow]?
}

struct SpecialAlertsResponse: Codable {
    var meta: ResponseMetaData
    var data: SpecialAlertsData?
}

enum QuantumValue: Codable, Equatable {
    
    case int(Int), string(String), float(Float)
    
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
        }
    }
    
    var stringValue: String? {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return value
        case .float(let value): return "\(value)"
        }
    }
    
    var floatValue: Float? {
        switch self {
        case .int(let value): return Float(value)
        case .string(let value): return Float(value)
        case .float(let value): return value
        }
    }
}
