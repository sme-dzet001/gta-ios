//
//  HomeDataProvider.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 02.12.2020.
//

import Foundation

class HomeDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    
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
        
        let res = NSMutableAttributedString(attributedString: htmlAttrString)
        
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return res }
        
        let wholeRange = NSRange(res.string.startIndex..., in: res.string)
        let matches = (mailRegex.matches(in: res.string, options: [], range: wholeRange))
        for match in matches {
            guard let mailLinkRange = Range(match.range, in: res.string) else { continue }
            let mailLinkStr = res.string[mailLinkRange]
            if let linkUrl = URL(string: "mailto:\(mailLinkStr)") {
                res.addAttribute(.link, value: linkUrl, range: match.range)
            }
        }
        return res
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
            self?.cacheData(reportResponse, path: .getSpecialAlerts)
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalNews.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.getCachedResponse(for: .getGlobalNews) { (data, error) in
                    if let _ = data {
                        self?.processGlobalNews(newsResponse: data, reportDataResponse: reportData, error: error, errorCode: errorCode, completion: completion)
                    }
                }
                self?.apiManager.getGlobalNews(generationNumber: generationNumber) { (newsResponse, errorCode, error) in
                    self?.cacheData(newsResponse, path: .getGlobalNews)
                    self?.processGlobalNews(newsResponse: newsResponse, reportDataResponse: reportData, error: error, errorCode: errorCode, completion: completion)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func processGlobalNews(newsResponse: Data?, reportDataResponse: ReportDataResponse?, error: Error?, errorCode: Int, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            self.fillNewsData(with: newsResponse, indexes: self.getDataIndexes(columns: reportDataResponse?.meta.widgetsDataSource?.globalNews?.columns) )
        }
        completion?(errorCode, retErr)
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
    
    private func processSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.specialAlerts.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            getCachedResponse(for: .getSpecialAlerts) {[weak self] (data, error) in
                if let _ = data {
                    self?.processSpecialAlerts(reportData, data, 200, error, completion)
                }
            }
            apiManager.getSpecialAlerts(generationNumber: generationNumber, completion: { [weak self] (alertsResponse, errorCode, error) in
                self?.cacheData(alertsResponse, path: .getSpecialAlerts)
                self?.processSpecialAlerts(reportData, alertsResponse, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error)
        }
    }
    
    func getSpecialAlertsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processSectionReport(data, 200, error, completion)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processSectionReport(reportResponse, errorCode, error, completion)
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
    
    private func cacheData(_ data: Data?, path: CacheManager.path) {
        guard let _ = data else { return }
        cacheManager.cacheResponse(responseData: data!, requestURI: path.rawValue) { (error) in
            if let error = error {
                print("Function: \(#function), line: \(#line), message: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCachedResponse(for path: CacheManager.path, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        cacheManager.getCachedResponse(requestURI: path.rawValue, completion: completion)
    }
    
}
