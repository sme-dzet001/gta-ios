//
//  HelpDeskResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

struct HelpDeskResponse: Codable {
    var data: [String : [HelpDeskValues]]?
    
    private var values: [String]? {
        guard let data = data, !data.isEmpty else { return [] }
        return data["rows"]?.first?.values
    }
    
    var serviceDeskPhoneNumber: String? {
        guard let values = values, values.count >= 5 else { return nil }
        return values[4]
    }
    var serviceDeskEmail: String?{
        guard let values = values, values.count >= 6 else { return nil }
        return values[5]
    }
}

struct HelpDeskValues: Codable {
    var values: [String]?
    
}


