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
        apiManager.getSectionReport(sectionId: APIManager.SectionId.home.rawValue) { [weak self] (reportResponse, errorCode, error) in
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
                        self?.fillNewsData(with: newsResponse)
                    }
                    completion?(errorCode, retErr)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillNewsData(with newsResponse: GlobalNewsResponse) {
        newsData = newsResponse.data?.rows ?? []
    }
    
    func getSpecialAlertsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.home.rawValue) { [weak self] (reportResponse, errorCode, error) in
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
                        self?.fillAlertsData(with: alertsResponse)
                    }
                    completion?(errorCode, retErr)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillAlertsData(with alertsResponse: SpecialAlertsResponse) {
        alertsData = alertsResponse.data?.rows ?? []
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
    
}
