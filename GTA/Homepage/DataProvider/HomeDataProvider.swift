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
    
    var newsDataIsEmpty: Bool {
        return newsData.isEmpty
    }
    
    var alertsDataIsEmpty: Bool {
        return alertsData.isEmpty
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
    
    private func processSpecialAlerts(_ reportData: ReportDataResponse?, _ alertsResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            fillAlertsData(with: alertsResponse, indexes: getDataIndexes(columns: reportData?.meta.widgetsDataSource?.globalNews?.columns))
        }
        completion?(errorCode, retErr)
    }
    
    private func processSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.specialAlerts.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            apiManager.getSpecialAlerts(generationNumber: generationNumber, cachedDataCallback: fromCache ? { [weak self] (alertsResponse, errorCode, error) in
                self?.processSpecialAlerts(reportData, alertsResponse, errorCode, error, completion)
            } : nil, completion: fromCache ? nil : { [weak self] (alertsResponse, errorCode, error) in
                self?.processSpecialAlerts(reportData, alertsResponse, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error)
        }
    }
    
    func getSpecialAlertsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(cachedDataCallback: { [weak self] (reportResponse, errorCode, error) in
            self?.processSectionReport(reportResponse, errorCode, error, true, completion)
        }, completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processSectionReport(reportResponse, errorCode, error, false, completion)
        })
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
