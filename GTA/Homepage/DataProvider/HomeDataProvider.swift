//
//  HomeDataProvider.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 02.12.2020.
//

import Foundation

class HomeDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    private(set) var newsData = [GlobalNewsRow]()
    private(set) var alertsData = [SpecialAlertRow]()
    private(set) var allOfficesData = [OfficeRow]()
    
    var newsDataIsEmpty: Bool {
        return newsData.isEmpty
    }
    
    var alertsDataIsEmpty: Bool {
        return alertsData.isEmpty
    }
    
    var allOfficesDataIsEmpty: Bool {
        return allOfficesData.isEmpty
    }
    
    var selectedOffice: OfficeRow? {
        return allOfficesData.first
    }
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func getPosterImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        apiManager.loadImageData(from: url, completion: completion)
    }
    
    func formNewsBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
        guard let encodedText = base64EncodedText, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8), let htmlAttrString = htmlBodyString.htmlToAttributedString else { return nil }
        return NSMutableAttributedString(attributedString: htmlAttrString)
    }
    
    func formatDateString(dateString: String?, initialDateFormat: String) -> String? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = initialDateFormat
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        dateFormatter.dateFormat = "HH:mm zzz E d"
        let formattedDateString = dateFormatter.string(from: date)
        return formattedDateString
    }
    
    func getGlobalNewsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalNews.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getGlobalNews(generationNumber: generationNumber) { (newsResponse, errorCode, error) in
                    var newsDataResponse: GlobalNewsResponse?
                    var retErr = error
                    if let responseData = newsResponse {
                        do {
                            newsDataResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    if let newsResponse = newsDataResponse {
                        self?.fillNewsData(with: newsResponse, indexes: self?.getDataIndexes(columns: reportData?.meta.widgetsDataSource?.globalNews?.columns) ?? [:])
                    }
                    completion?(errorCode, retErr)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillNewsData(with newsResponse: GlobalNewsResponse, indexes: [String : Int]) {
        var response: GlobalNewsResponse = newsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        newsData = response.data?.rows ?? []
    }
    
    func getSpecialAlertsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.specialAlerts.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getSpecialAlerts(generationNumber: generationNumber) { (alertsResponse, errorCode, error) in
                    var specialAlertsDataResponse: SpecialAlertsResponse?
                    var retErr = error
                    if let responseData = alertsResponse {
                        do {
                            specialAlertsDataResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    if let alertsResponse = specialAlertsDataResponse {
                        self?.fillAlertsData(with: alertsResponse, indexes: self?.getDataIndexes(columns: reportData?.meta.widgetsDataSource?.globalNews?.columns) ?? [:])
                    }
                    completion?(errorCode, retErr)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillAlertsData(with alertsResponse: SpecialAlertsResponse, indexes: [String : Int]) {
        var response: SpecialAlertsResponse = alertsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        alertsData = response.data?.rows ?? []
    }
    
    func getAllOfficesData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.officeStatus.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allOffices.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getAllOffices(generationNumber: generationNumber) { (officesResponse, errorCode, error) in
                    var allOfficesResponse: AllOfficesResponse?
                    var retErr = error
                    if let responseData = officesResponse {
                        do {
                            allOfficesResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    if let officesResponse = allOfficesResponse {
                        self?.fillAllOfficesData(with: officesResponse, indexes: self?.getDataIndexes(columns: reportData?.meta.widgetsDataSource?.allOffices?.columns) ?? [:])
                    }
                    completion?(errorCode, retErr)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillAllOfficesData(with officesResponse: AllOfficesResponse, indexes: [String : Int]) {
        var response: AllOfficesResponse = officesResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        allOfficesData = response.data?.rows ?? []
    }
    
    func getAllOfficeRegions() -> [String] {
        let regions = allOfficesData.compactMap { $0.officeRegion }
        return regions.removeDuplicates().sorted()
    }
    
    func getOffices(for region: String) -> [OfficeRow] {
        let selectedRegionOffices = allOfficesData.filter { $0.officeRegion == region }
        let sortedOffices = selectedRegionOffices.sorted { ($0.officeName ?? "") < ($1.officeName ?? "") }
        return sortedOffices
    }
    
    func getOfficeNames(for region: String) -> [String] {
        return getOffices(for: region).compactMap { $0.officeName }
    }
    
    private func parseSectionReport(data: Data?) -> ReportDataResponse? {
        var reportDataResponse: ReportDataResponse?
        if let responseData = data {
            do {
                reportDataResponse = try DataParser.parse(data: responseData)
            } catch {
                print("Function: \(#function), line: \(#line), message: \(error.localizedDescription)")
            }
        }
        return reportDataResponse
    }
    
    private func getDataIndexes(columns: [ColumnName]?) -> [String : Int] {
        var indexes: [String : Int] = [:]
        guard let columns = columns else { return indexes}
        for (index, column) in columns.enumerated() {
            if let name = column.name {
                indexes[name] = index
            }
        }
        return indexes
    }
    
}
