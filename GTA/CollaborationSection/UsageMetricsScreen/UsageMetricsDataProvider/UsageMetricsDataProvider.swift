//
//  UsageMetricsDataProvider.swift
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

class UsageMetricsDataProvider {
    var teamsByFunctionsUsersData: [TeamsByFunctionsDataEntry] = [
//        TeamsByFunctionsDataEntry(refreshDate: "6/30/2020 0:00", value: 101590),
//        TeamsByFunctionsDataEntry(refreshDate: "7/31/2020 0:00", meetingCount: 94287),
//        TeamsByFunctionsDataEntry(refreshDate: "8/31/2020 0:00", meetingCount: 72159),
//        TeamsByFunctionsDataEntry(refreshDate: "9/30/2020 0:00", meetingCount: 151637),
//        TeamsByFunctionsDataEntry(refreshDate: "10/30/2020 0:00", meetingCount: 159971),
//        TeamsByFunctionsDataEntry(refreshDate: "11/29/2020 0:00", meetingCount: 138701, callCount: 126817, privateChatMessageCount: 1974617, teamsChatMessageCount: 20299),
//        TeamsByFunctionsDataEntry(refreshDate: "12/31/2020 0:00", meetingCount: 104350, callCount: 92473, privateChatMessageCount: 1567082, teamsChatMessageCount: 13601),
//        TeamsByFunctionsDataEntry(refreshDate: "1/31/2021 0:00", meetingCount: 150870, callCount: 125149, privateChatMessageCount: 2142882, teamsChatMessageCount: 18070),
//        TeamsByFunctionsDataEntry(refreshDate: "2/28/2021 0:00", meetingCount: 167459, callCount: 145455, privateChatMessageCount: 2431505, teamsChatMessageCount: 23668),
//        TeamsByFunctionsDataEntry(refreshDate: "3/31/2021 0:00", meetingCount: 186415, callCount: 162648, privateChatMessageCount: 2710205, teamsChatMessageCount: 27430),
//        TeamsByFunctionsDataEntry(refreshDate: "4/28/2021 0:00", meetingCount: 176097, callCount: 167927, privateChatMessageCount: 2650130, teamsChatMessageCount: 24007),
//        TeamsByFunctionsDataEntry(refreshDate: "5/17/2021 0:00", meetingCount: 176767, callCount: 164237, privateChatMessageCount: 2610546, teamsChatMessageCount: 23635)
    ]
    
}
