//
//  CollaborationResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 10.03.2021.
//

import Foundation

struct CollaborationDetailsResponse: Codable, Equatable {
    var meta: ResponseMetaData?
    var data: [String : CollaborationDetailsData?]?
    var indexes: [String : Int] = [:]
    
    var isEmpty: Bool {
        if let _ = values, let _ = title, let _ = description {
            return false
        }
        return true
    }
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
    
    private var values: [QuantumValue?]? {
        return data?.first?.value?.data?.rows?.first?.values
    }
    
    var icon: String? {
        guard let valuesArr = values, let index = indexes["icon"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var title: String? {
        guard let valuesArr = values, let index = indexes["app suite"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var type: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var description: String? {
        guard let valuesArr = values, let index = indexes["description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var groupName: String? {
        guard let valuesArr = values, let index = indexes["group name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func ==(lhs: CollaborationDetailsResponse, rhs: CollaborationDetailsResponse) -> Bool {
        return lhs.description == rhs.description && lhs.title == rhs.title //&& lhs.title == rhs.title
    }
    
}

struct CollaborationDetailsData: Codable {
    var data: CollaborationDetailsRows?
}

struct CollaborationDetailsRows: Codable {
    var rows: [CollaborationDetailsRow]?
}

struct CollaborationDetailsRow: Codable {
    var values: [QuantumValue?]?
}

struct CollaborationTipsAndTricksResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : TipsAndTricksData?]?
}

struct TipsAndTricksData: Codable {
    var data: TipsAndTricksRows?
}

struct TipsAndTricksRow: Codable, QuickHelpDataProtocol, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    var question: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var answer: String? {
        guard let valuesArr = values, let index = indexes["body"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var banner: String? {
        guard let valuesArr = values, let index = indexes["banner"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
}

struct TipsAndTricksRows: Codable {
    var rows: [TipsAndTricksRow]?
}

protocol QuickHelpDataProtocol {
    var question: String? {get}
    var answer: String?{get}
}


struct CollaborationAppDetailsResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : CollaborationAppDetailsData?]?
}

struct CollaborationAppDetailsData: Codable {
    var data: CollaborationAppDetailsRows?
}

struct CollaborationAppDetailsRows: Codable, Equatable {
    var rows: [CollaborationAppDetailsRow]?
    
}

struct CollaborationAppDetailsRow: Codable, Equatable, ImageDataProtocol {
    var values: [QuantumValue?]?
    
    var indexes: [String : Int] = [:]
    var imageData: Data?
    var imageStatus: LoadingStatus = .loading
    var fullImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var openAppUrl: String? {
        guard let valuesArr = values, let index = indexes["open app url"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var description: String? {
        guard let valuesArr = values, let index = indexes["description"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportPhone: String? {
        guard let valuesArr = values, let index = indexes["app support phone"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var productPageUrl: String? {
        guard let valuesArr = values, let index = indexes["product page url"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var imageUrl: String? {
        guard let valuesArr = values, let index = indexes["icon"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var title: String? {
        guard let valuesArr = values, let index = indexes["title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportUrl: String? {
        guard let valuesArr = values, let index = indexes["app support url"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appName: String? {
        guard let valuesArr = values, let index = indexes["app name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSuite: String? {
        guard let valuesArr = values, let index = indexes["app suite"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var appSupportPolicy: String? {
        guard let valuesArr = values, let index = indexes["app support policy"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var fullTitle: String? {
        guard let valuesArr = values, let index = indexes["app name full"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func ==(lhs: CollaborationAppDetailsRow, rhs: CollaborationAppDetailsRow) -> Bool {
        return lhs.description == rhs.description && lhs.title == rhs.title && lhs.appSupportUrl == rhs.appSupportUrl && lhs.appSupportPolicy == rhs.appSupportPolicy && lhs.productPageUrl == rhs.productPageUrl && lhs.openAppUrl == rhs.openAppUrl
    }
    
}

struct CollaborationNewsResponse: Codable {
    var meta: ResponseMetaData?
    var data: CollaborationNewsRows?
}

struct CollaborationNewsRows: Codable, Equatable {
    var rows: [CollaborationNewsRow]?
}

struct CollaborationNewsRow: Codable, Equatable, ImageDataProtocol {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    var imageData: Data?
    var imageStatus: LoadingStatus = .loading
    
    var decodeBody: NSMutableAttributedString?
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    var headline: String? {
        guard let valuesArr = values, let index = indexes["headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var subHeadline: String? {
        guard let valuesArr = values, let index = indexes["sub headline"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var imageUrl: String? {
        guard let valuesArr = values, let index = indexes["banner"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var postDate: String? {
        guard let valuesArr = values, let index = indexes["post date"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var body: String? {
        guard let valuesArr = values, let index = indexes["body"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var byLine: String? {
        guard let valuesArr = values, let index = indexes["by line"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    static func ==(lhs: CollaborationNewsRow, rhs: CollaborationNewsRow) -> Bool {
        return lhs.body == rhs.body && lhs.headline == rhs.headline && lhs.subHeadline == rhs.subHeadline && lhs.imageUrl == rhs.imageUrl && lhs.byLine == rhs.byLine
    }
    
}

struct CollaborationMetricsResponse: Codable, Equatable {
    
    var meta: ResponseMetaData?
    var data: [String : [String: CollaborationMetricsData?]?]?//CollaborationMetricsRows?
    var appGroup: String?
    var appName: String?
    
    var collaborationMetricsData: CollaborationMetricsData? {
        let key = data?.keys.first(where: {$0 == appGroup}) ?? ""
        guard let metricsData = data?[key]??[appName ?? ""] else { return nil }
        return metricsData
    }
    
    var appNames: [String] {
        let key = data?.keys.first(where: {$0 == appGroup}) ?? ""
        guard let names = data?[key]??.compactMap({$0.key}) else { return [] }
        return names
    }
    
    enum CodingKeys: String, CodingKey {
        case meta, data
    }
    
    static func == (lhs: CollaborationMetricsResponse, rhs: CollaborationMetricsResponse) -> Bool {
        return lhs.collaborationMetricsData == rhs.collaborationMetricsData && lhs.data == rhs.data
    }
    
}

struct CollaborationMetricsData: Codable, Equatable {
    var data: CollaborationMetricsRows?
}

struct CollaborationMetricsRows: Codable, Equatable {
    var rows: [CollaborationMetricsRow?]?
}
 
struct CollaborationMetricsRow: Codable, Equatable {
    var values: [QuantumValue?]?
    var indexes: [String : Int] = [:]
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    private var chartTypeString: String? {
        guard let valuesArr = values, let index = indexes["chart_type"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var chartType: ChartType {
        guard let type = ChartType(rawValue: chartTypeString ?? "") else { return .none }
        return type
    }
    
    var appName: String? {
        guard let valuesArr = values, let index = indexes["app_name"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var chartSubtitle: String? {
        guard let valuesArr = values, let index = indexes["chart_subtitle"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var chartTitle: String? {
        guard let valuesArr = values, let index = indexes["chart_title"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var chartPosition: Int? {
        guard let valuesArr = values, let index = indexes["chart_position"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.intValue
    }
    
    var chartSubposition: Float? {
        guard let valuesArr = values, let index = indexes["chart_subposition"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.floatValue
    }
    
    var legend: String? {
        guard let valuesArr = values, let index = indexes["legend"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.stringValue
    }
    
    var value: Float? {
        guard let valuesArr = values, let index = indexes["value"], valuesArr.count > index else { return nil }
        return valuesArr[index]?.floatValue
    }
    
}

enum ChartType: String {
    case line = "line"
    case verticalBar = "vertical-bar"
    case horizontalBar = "horizontal-bar"
    case none = ""
}

protocol ImageDataProtocol {
    //var fullTitle: String? { get }
    var imageData: Data? { get set }
    var imageStatus: LoadingStatus { get set }
    var imageUrl: String? { get }
}
