//
//  ChartsDataStructures.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import Foundation

struct TeamsByFunctionsDataEntry {
    var refreshDate: String?
    var value: Int?
    
    var formattedLegend: String? {
        let sourceDateFormatter = DateFormatter()
        sourceDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        sourceDateFormatter.dateFormat = String.convertMetricsDateFormat
        if let period = refreshDate, let date = sourceDateFormatter.date(from: period) {
            let targetDateFormatter = DateFormatter()
            targetDateFormatter.dateFormat = "dd-MMM"
            return targetDateFormatter.string(from: date)
        }
        return nil
    }
}

struct ActiveUsersDataEntry {
    var period: String?
    var value: Int?
}

struct TeamsChatUserDataEntry {
    var percent: Double?
    var countryCode: String?
}

struct ChartStructure {
    var title: String
    var values: [Float]
    var legends: [String]
}
