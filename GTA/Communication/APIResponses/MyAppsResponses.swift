//
//  MyAppsResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 08.12.2020.
//

import Foundation

struct AllAppsResponse: Codable, Equatable {
    var meta: ResponseMetaData
    var data: AllAppsRows?
    var indexes: [String : Int] = [:]
    
    var myAppsStatus: [AppInfo] {
        var status = [AppInfo]()
        data?.rows?.forEach({ (value) in
            if let valuesArray = value.values, let nameIndex = indexes["app name"], let titleIndex = indexes["app title"], let iconIndex = indexes["app icon"], let statusIndex = indexes["status"], let lastUpdateIndex = indexes["last update"] {
                let appName = valuesArray.count > nameIndex ? valuesArray[nameIndex]?.stringValue : ""
                let appTitle = valuesArray.count > titleIndex ? valuesArray[titleIndex]?.stringValue : ""
                let appIcon = valuesArray.count > iconIndex ? valuesArray[iconIndex]?.stringValue : ""
                let appStatus = valuesArray.count > statusIndex ? valuesArray[statusIndex]?.stringValue : ""
                let appLastUpdate = valuesArray.count > lastUpdateIndex ? valuesArray[lastUpdateIndex]?.stringValue : ""
                let appImageData = AppsImageData(app_icon: appIcon, imageData: nil, imageStatus: .loading)
                let appInfo = AppInfo(app_name: appName, app_title: appTitle, appImageData: appImageData, appStatus: SystemStatus(status: appStatus), app_is_active: true, lastUpdateDate: appLastUpdate)
                status.append(appInfo)
            }
        })
        return status
    }
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
    
    static func == (lhs: AllAppsResponse, rhs: AllAppsResponse) -> Bool {
        return lhs.myAppsStatus == rhs.myAppsStatus
    }
    
}

struct AllAppsRows: Codable {
    var rows: [AllAppsValues]?
}

struct AllAppsValues: Codable {
    var values: [QuantumValue?]?
}

struct AppInfo: Equatable {
    var app_name: String?
    var app_title: String?
    var appImageData: AppsImageData
    var appStatus: SystemStatus
    var app_is_active: Bool
    var lastUpdateDate: String?
}

struct AppsImageData: Equatable {
    var app_icon: String?
    var imageData: Data?
    var imageStatus: ImageLoadingStatus = .loading
    
    enum ImageLoadingStatus {
        case loading
        case failed
        case loaded
    }
    
    static func == (lhs: AppsImageData, rhs: AppsImageData) -> Bool {
        return lhs.imageData == rhs.imageData && lhs.app_icon == rhs.app_icon
    }
}


struct MyAppsResponse: Codable, Equatable {
    var meta: ResponseMetaData
    var data: [String : MyAppsData]?
    var indexes: [String : Int] = [:]
    var values: [MyAppsValues]? {
        return data?.first?.value.data?.rows
    }

    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
    
    static func == (lhs: MyAppsResponse, rhs: MyAppsResponse) -> Bool {
        return lhs.values == rhs.values
    }
}

struct MyAppsData: Codable {
    var data: MyAppsRows?
}

struct MyAppsRows: Codable {
    var rows: [MyAppsValues]?
    var requestDate: String?
}

struct MyAppsValues: Codable, Equatable {
    var values: [QuantumValue?]?
    
    static func == (lhs: MyAppsValues, rhs: MyAppsValues) -> Bool {
        var isEqual: Bool = false
        if lhs.values == rhs.values {
            isEqual = true
        }
        return isEqual
    }
    
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
        case "up": self = .online
        case "down": self = .offline
        case "has issues": self = .pendingAlerts
        case "has issue": self = .pendingAlerts
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

struct AppContactsData: Codable {
    var meta: ResponseMetaData
    var data: [String : UserData]?
    
    var indexes: [String : Int] = [:]
    
    var contactsData: [ContactData]? {
        guard let appContactRows = data?.first?.value.data?.rows else { return nil }
        guard let appContactEmailIdx = indexes["app contact email"] else { return nil }
        guard let appContactNameIdx = indexes["app contact name"] else { return nil }
        guard let appContactTitleIdx = indexes["app contact title"] else { return nil }
        guard let appContactPictureIdx = indexes["profile picture"] else { return nil }
        guard let appContactLocationIdx = indexes["location"] else { return nil }
        guard let appContactBioIdx = indexes["bio"] else { return nil }
        guard let appContactFunFactIdx = indexes["fun fact"] else { return nil }
        var res = appContactRows.map({ (appContact) -> ContactData in
            guard let values = appContact.values else { return ContactData() }
            let appContactEmail = values[appContactEmailIdx]?.stringValue
            let appContactName = values[appContactNameIdx]?.stringValue
            let appContactTitle = values[appContactTitleIdx]?.stringValue
            let appContactPhotoUrl = values[appContactPictureIdx]?.stringValue
            let appContactLocation = values[appContactLocationIdx]?.stringValue
            let appContactBio = values[appContactBioIdx]?.stringValue
            let appContactFunFact = values[appContactFunFactIdx]?.stringValue
            return ContactData(contactPhotoUrl: appContactPhotoUrl, contactName: appContactName, contactEmail: appContactEmail, contactPosition: appContactTitle, contactLocation: appContactLocation, contactBio: appContactBio, contactFunFact: appContactFunFact)
        })
        res.removeAll(where: {$0.contactName == nil || ($0.contactName ?? "").isEmpty || $0.contactEmail == nil || ($0.contactEmail ?? "").isEmpty})
        return res
    }
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
}

struct AppDetailsData: Codable {
    var meta: ResponseMetaData
    var data: [String : UserData]?
    
    var indexes: [String : Int] = [:]
    
    private var values: [QuantumValue?]? {
        let rows = data?.first?.value.data?.rows?.first?.values
        return rows
    }
    
    var appTitle: String? {
        guard let _ = values, let index = indexes["app title"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appDescription: String? {
        guard let _ = values, let index = indexes["app desc"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appSupportEmail: String? {
        guard let _ = values, let index = indexes["app support email"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appWikiUrl: String? {
        guard let _ = values, let index = indexes["app wiki url"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appJiraSupportUrl: String? {
        guard let _ = values, let index = indexes["app jira support url"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appSupportPolicy: String? {
        guard let _ = values, let index = indexes["app support policy"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    var appTeamContact: String? {
        guard let _ = values, let index = indexes["app team contact"], values!.count > index else { return nil }
        return values?[index]?.stringValue
    }
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
}

struct UserData: Codable {
    var data: AppDetailsDataRows?
}

struct AppDetailsDataRows: Codable {
    var rows: [AppDetailsValues]?
}

struct AppDetailsValues: Codable {
    var values: [QuantumValue?]?
}
