//
//  UsageMetricsDataProvider.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import Foundation

struct TeamsByFunctionsDataEntry {
    var refreshDate: String?
    var meetingCount: Int?
    var callCount: Int?
    var privateChatMessageCount: Int?
    var teamsChatMessageCount: Int?
}

struct ActiveUsersDataEntry {
    var period: String?
    var value: Int?
}

struct TeamsChatUserDataEntry {
    var percent: Double?
    var countryCode: String?
}

class UsageMetricsDataProvider {
    var teamsByFunctionsUsersData: [TeamsByFunctionsDataEntry] = [
        TeamsByFunctionsDataEntry(refreshDate: "6/30/2020 0:00", meetingCount: 101590, callCount: 64478, privateChatMessageCount: 2146806, teamsChatMessageCount: 18480),
        TeamsByFunctionsDataEntry(refreshDate: "7/31/2020 0:00", meetingCount: 94287, callCount: 59145, privateChatMessageCount: 1914668, teamsChatMessageCount: 17711),
        TeamsByFunctionsDataEntry(refreshDate: "8/31/2020 0:00", meetingCount: 72159, callCount: 46356, privateChatMessageCount: 1790575, teamsChatMessageCount: 18262),
        TeamsByFunctionsDataEntry(refreshDate: "9/30/2020 0:00", meetingCount: 151637, callCount: 125694, privateChatMessageCount: 2224187, teamsChatMessageCount: 22870),
        TeamsByFunctionsDataEntry(refreshDate: "10/30/2020 0:00", meetingCount: 159971, callCount: 135916, privateChatMessageCount: 2318612, teamsChatMessageCount: 22983),
        TeamsByFunctionsDataEntry(refreshDate: "11/29/2020 0:00", meetingCount: 138701, callCount: 126817, privateChatMessageCount: 1974617, teamsChatMessageCount: 20299),
        TeamsByFunctionsDataEntry(refreshDate: "12/31/2020 0:00", meetingCount: 104350, callCount: 92473, privateChatMessageCount: 1567082, teamsChatMessageCount: 13601),
        TeamsByFunctionsDataEntry(refreshDate: "1/31/2021 0:00", meetingCount: 150870, callCount: 125149, privateChatMessageCount: 2142882, teamsChatMessageCount: 18070),
        TeamsByFunctionsDataEntry(refreshDate: "2/28/2021 0:00", meetingCount: 167459, callCount: 145455, privateChatMessageCount: 2431505, teamsChatMessageCount: 23668),
        TeamsByFunctionsDataEntry(refreshDate: "3/31/2021 0:00", meetingCount: 186415, callCount: 162648, privateChatMessageCount: 2710205, teamsChatMessageCount: 27430),
        TeamsByFunctionsDataEntry(refreshDate: "4/28/2021 0:00", meetingCount: 176097, callCount: 167927, privateChatMessageCount: 2650130, teamsChatMessageCount: 24007),
        TeamsByFunctionsDataEntry(refreshDate: "5/17/2021 0:00", meetingCount: 176767, callCount: 164237, privateChatMessageCount: 2610546, teamsChatMessageCount: 23635)
    ]
    
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
