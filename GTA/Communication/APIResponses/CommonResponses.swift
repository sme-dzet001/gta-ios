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
        case widgetsDataSource = "widget"
    }
}

struct WidgetsDataSource: Codable {
    var params: WidgetsDataSourceColumns?
}

struct WidgetsDataSourceColumns: Codable {
    var columns: [ColumnName?]?
}

struct ColumnName: Codable {
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "header"
    }
}

// MARK: - Report Response

struct SectionWidget: Codable, Equatable {
    var generationNumber: Int
    var widgetId: String
    
    enum CodingKeys: String, CodingKey {
        case generationNumber = "generation"
        case widgetId = "widget_id"
    }
}

struct ReportSection: Codable, Equatable {
    var title: String
    var sectionId: String
    var quantumId: QuantumValue
    var widgets: [SectionWidget]?
    var id: String? {
        quantumId.stringValue
    }
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case sectionId = "section_id"
        case quantumId = "_id"
        case widgets = "widgets"
    }
    
    static func == (lhs: ReportSection, rhs: ReportSection) -> Bool {
        lhs.id == rhs.id && lhs.sectionId == rhs.sectionId && lhs.widgets == rhs.widgets
    }
    
}

struct ReportDataResponse: Codable, Equatable {
    var meta: ResponseMetaData
    var data: [ReportSection]?
 
    static func == (lhs: ReportDataResponse, rhs: ReportDataResponse) -> Bool {
        lhs.data == rhs.data
    }
}
