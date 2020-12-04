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
    
    func formNewsBody(from base64EncodedText: String?) -> String? {
        guard let encodedText = base64EncodedText else { return nil }
        guard let data = Data(base64Encoded: encodedText) else { return encodedText }
        return String(data: data, encoding: .utf8)
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
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalNews.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getGlobalNews(generationNumber: generationNumber) { (newsResponse, errorCode, error) in
                    if let newsResponse = newsResponse {
                        self?.fillNewsData(with: newsResponse)
                    }
                    completion?(errorCode, error)
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
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.specialAlerts.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getSpecialAlerts(generationNumber: generationNumber) { (alertsResponse, errorCode, error) in
                    if let alertsResponse = alertsResponse {
                        self?.fillAlertsData(with: alertsResponse)
                    }
                    completion?(errorCode, error)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillAlertsData(with alertsResponse: SpecialAlertsResponse) {
        alertsData = alertsResponse.data?.rows ?? []
    }
    
}
