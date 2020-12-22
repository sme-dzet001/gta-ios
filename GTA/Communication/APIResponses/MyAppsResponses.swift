//
//  MyAppsResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 08.12.2020.
//

import Foundation

struct AllAppsResponse: Codable {
    var data: AllAppsRows?
    
    var myAppsStatus: [AppInfo] {
        var status = [AppInfo]()
        data?.rows?.forEach({ (value) in
            if let valuesArray = value.values {
                let appName = valuesArray.count > 1 ? valuesArray[1].stringValue : ""
                let appTitle = valuesArray.count > 2 ? valuesArray[2].stringValue : ""
                let appIcon = valuesArray.count > 3 ? valuesArray[3].stringValue : ""
                status.append(AppInfo(app_name: appName, app_title: appTitle, app_icon: appIcon, appStatus: .none, app_is_active: true))
            }
        })
        return status
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

struct AllAppsRows: Codable {
    var rows: [AllAppsValues]?
}

struct AllAppsValues: Codable {
    var values: [QuantumValue]?
}

struct AppInfo {
    var app_name: String?
    var app_title: String?
    var app_icon: String?
    var appStatus: SystemStatus
    var app_is_active: Bool
    var imageData: Data?
    var isImageDataEmpty: Bool = false
}


struct MyAppsResponse: Codable {

    var data: [String : MyAppsData]?
    
    var values: [MyAppsValues]? {
        return data?.first?.value.data?.rows
    }

    enum CodingKeys: String, CodingKey {
        case data
    }
}

struct MyAppsData: Codable {
    var data: MyAppsRows?
}

struct MyAppsRows: Codable {
    var rows: [MyAppsValues]?
}

struct MyAppsValues: Codable {
    var values: [QuantumValue]?
}


struct AppsDataSource {
    var sectionName: String?
    var description: String?
    var cellData: [AppInfo]
    var metricsData: MetricsData? = nil
}

enum SystemStatus {
    init(status: String?) {
        switch status?.lowercased() {
        case "Up": self = .online
        case "offline": self = .offline
        case "Pending Alerts": self = .pendingAlerts
        default: self = .none
        }
    }
    case online
    case offline
    case pendingAlerts
    case none
}

struct MetricsData {
    var dailyData: [ChartData]
    var weeklyData: [ChartData]
    var monthlyData: [ChartData]
}

struct ChartData {
    var legendTitle: String?
    var periodFullTitle: String?
    var value: Int?
}

struct AppDetailsData: Codable {
    var data: [String : [String : [String: [String: [[String : [QuantumValue?]]]]]]]? //temp
    
    var appKey: String? = nil
    private var values: [QuantumValue?]? {
        var nameKey = data?.first(where: {$0.value[appKey ?? ""] != nil})?.key //temp
        if nameKey == nil {
            nameKey = data?.first(where: {$0.value["SCUBA"] != nil})?.key ?? ""
            let rows = data?[nameKey ?? ""]?["SCUBA"]?["data"]?["rows"]?.first
            return rows?["values"]
        }
        let rows = data?[nameKey ?? ""]?[appKey ?? ""]?["data"]?["rows"]?.first
        return rows?["values"]
    }
    
    var appTitle: String? {
        guard let _ = values, values!.count >= 3 else { return nil }
        return values?[2]?.stringValue
    }
    
    var appDescription: String? {
        guard let _ = values, values!.count >= 4 else { return nil }
        return values?[3]?.stringValue
    }
    
    var appSupportEmail: String? {
        guard let _ = values, values!.count >= 6 else { return nil }
        return values?[5]?.stringValue
    }
    
    var appWikiUrl: String? {
        guard let _ = values, values!.count >= 7 else { return nil }
        return values?[6]?.stringValue
    }
    
    var appJiraSupportUrl: String? {
        guard let _ = values, values!.count >= 8 else { return nil }
        return values?[7]?.stringValue
    }
    
    var appSupportPolicy: String? {
        guard let _ = values, values!.count >= 9 else { return nil }
        return values?[8]?.stringValue
    }
    
    var appTeamContact: String? {
        guard let _ = values, values!.count >= 10 else { return nil }
        return values?[9]?.stringValue
    }
    
}

struct UserData: Codable {
    var data: AppDetailsDataRows?
}

struct AppDetailsDataRows: Codable {
    var rows: [AppDetailsValues]?
}

struct AppDetailsValues: Codable {
    var values: [QuantumValue]?
}
