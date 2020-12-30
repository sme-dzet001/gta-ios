//
//  CommonResponses.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 27.11.2020.
//

import Foundation

struct ResponseMetaData: Codable {
    var responseCode: Int
    var userInstructions: String?
    var userMessage: String?
    var widgetsDataSource: WidgetsDataSource?
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "code"
        case userInstructions = "user_instructions"
        case userMessage = "user_message"
        case widgetsDataSource = "widgets_datasource"
    }
}

struct WidgetsDataSource: Codable {
    
    var globalNews: WidgetsDataSourceColumns?
    var officeStatus: WidgetsDataSourceColumns?
    var allOffices: WidgetsDataSourceColumns?
    var specialAlerts: WidgetsDataSourceColumns?
    var gsdTeamContacts: WidgetsDataSourceColumns?
    var gsdQuickHelp: WidgetsDataSourceColumns?
    var gsdProfile: WidgetsDataSourceColumns?
    var myAppsStatus: WidgetsDataSourceColumns?
    var allApps: WidgetsDataSourceColumns?
    var appDetails: WidgetsDataSourceColumns?
    var appContacts: WidgetsDataSourceColumns?
    
    enum CodingKeys: String, CodingKey {
        case globalNews = "global_news"
        case officeStatus = "office_status"
        case allOffices = "all_offices"
        case specialAlerts = "special_alerts"
        case gsdTeamContacts = "gsd_team_contacts"
        case gsdQuickHelp = "gsd_quick_help"
        case gsdProfile = "gsd_profile"
        case myAppsStatus = "my_apps_status"
        case allApps = "all_apps"
        case appDetails = "app_details"
        case appContacts = "app_contacts"
    }
    
}

struct WidgetsDataSourceColumns: Codable {
    var columns: [ColumnName]?
}

struct ColumnName: Codable {
    var name: String?
}

// MARK: - Report Response

struct SectionWidget: Codable {
    var generationNumber: Int
    var widgetId: String
    
    enum CodingKeys: String, CodingKey {
        case generationNumber = "generation"
        case widgetId = "widget_id"
    }
}

struct ReportSection: Codable {
    var title: String
    var sectionId: String
    var id: String
    var widgets: [SectionWidget]?
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case sectionId = "section_id"
        case id = "_id"
        case widgets = "widgets"
    }
}

struct ReportDataResponse: Codable {
    var meta: ResponseMetaData
    var data: [ReportSection]?
}
