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

struct TeamsChatUserDataEntry {
    var percent: Double?
    var countryCode: String?
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
    
    var teamsChatUserData: [TeamsChatUserDataEntry] = [
        TeamsChatUserDataEntry(percent: 60.20, countryCode: "GSA"),
        TeamsChatUserDataEntry(percent: 39.20, countryCode: "ESP"),
        TeamsChatUserDataEntry(percent: 23.60, countryCode: "BRA"),
        TeamsChatUserDataEntry(percent: 17.40, countryCode: "CAN"),
        TeamsChatUserDataEntry(percent: 11.90, countryCode: "USA"),
        TeamsChatUserDataEntry(percent: 11.80, countryCode: "MEX"),
        TeamsChatUserDataEntry(percent: 9.90, countryCode: "IND"),
        TeamsChatUserDataEntry(percent: 8.20, countryCode: "FRA"),
        TeamsChatUserDataEntry(percent: 5.10, countryCode: "GBR"),
        TeamsChatUserDataEntry(percent: 4.30, countryCode: "AUS"),
    ]
}
