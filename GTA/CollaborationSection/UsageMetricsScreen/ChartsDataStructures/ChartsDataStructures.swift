//
//  ChartsDataStructures.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import Foundation

struct TeamsByFunctionsLineChartData: MetricsPosition {
    var title: String?
    var data: [[TeamsByFunctionsDataEntry]]?
    var position: Int?
}

struct TeamsByFunctionsDataEntry {
    var refreshDate: String?
    var value: Int?
    
    var formattedLegend: String? {
        guard let period = refreshDate else { return nil }
        return period.getDateForUsageMetrics()
    }
    var chartSubtitle: String?
}

struct ActiveUsersDataEntry {
    var period: String?
    var value: Int?
}

struct TeamsChatUserData: MetricsPosition {
    var title: String?
    var data: [TeamsChatUserDataEntry]?
    var position: Int?
}

struct TeamsChatUserDataEntry {
    var percent: Double?
    var countryCode: String?
}

struct ChartStructure: MetricsPosition {
    var title: String
    var values: [Float]
    var legends: [String]
    var chartType: ChartType
    var position: Int?
}

protocol MetricsPosition {
    var position: Int? { get set }
}
