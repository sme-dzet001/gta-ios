//
//  UsageMetricsDataProvider.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import Foundation

struct ActiveUsersDataEntry {
    var period: String?
    var value: Int?
}

class UsageMetricsDataProvider {
    var activeUsersData: [ActiveUsersDataEntry] = [
        ActiveUsersDataEntry(period: "31-Jul-20", value: 4433),
        ActiveUsersDataEntry(period: "31-Aug-20", value: 4483),
        ActiveUsersDataEntry(period: "30-Sep-20", value: 4592),
        ActiveUsersDataEntry(period: "30-Oct-20", value: 4711),
        ActiveUsersDataEntry(period: "29-Nov-20", value: 4761),
        ActiveUsersDataEntry(period: "31-Dec-20", value: 4801),
        ActiveUsersDataEntry(period: "31-Jan-21", value: 4943),
        ActiveUsersDataEntry(period: "28-Feb-21", value: 5056),
        ActiveUsersDataEntry(period: "31-Mar-21", value: 5187),
        ActiveUsersDataEntry(period: "28-Apr-21", value: 5363),
        ActiveUsersDataEntry(period: "31-May-21", value: 5515),
        ActiveUsersDataEntry(period: "22-Jun-21", value: 5669)
    ]
}
