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
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "code"
        case userInstructions = "user_instructions"
        case userMessage = "user_message"
    }
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
