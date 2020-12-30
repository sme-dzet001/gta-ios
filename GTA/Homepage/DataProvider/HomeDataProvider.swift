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
    private(set) var allOfficesData = [OfficeRow]()
    private var selectedOfficeId: Int?
    
    var newsDataIsEmpty: Bool {
        return newsData.isEmpty
    }
    
    var alertsDataIsEmpty: Bool {
        return alertsData.isEmpty
    }
    
    var allOfficesDataIsEmpty: Bool {
        return allOfficesData.isEmpty
    }
    
    private var defaultOffice: OfficeRow? {
        return allOfficesData.first
    }
    
    private var selectedOffice: OfficeRow? {
        guard let officeId = selectedOfficeId else { return nil }
        return allOfficesData.first { $0.officeId == officeId }
    }
    
    var userOffice: OfficeRow? {
        return selectedOffice ?? defaultOffice
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
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processGlobalNewsSectionReport(data, 200, error, completion)
            }
        }
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processGlobalNewsSectionReport(reportResponse, errorCode, error, completion)
        }
    }
    
    private func processGlobalNewsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalNews.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            getCachedResponse(for: .getGlobalNews) { [weak self] (data, error) in
                if let _ = data {
                    self?.processGlobalNews(newsResponse: data, reportDataResponse: reportData, error: error, errorCode: 200, completion: completion)
                }
            }
            apiManager.getGlobalNews(generationNumber: generationNumber) { [weak self] (newsResponse, errorCode, error) in
                self?.cacheData(newsResponse, path: .getGlobalNews)
                self?.processGlobalNews(newsResponse: newsResponse, reportDataResponse: reportData, error: error, errorCode: errorCode, completion: completion)
            }
        } else {
            completion?(errorCode, error)
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
    
    private func processSpecialAlertsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
                self?.processSpecialAlertsSectionReport(data, 200, error, completion)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processSpecialAlertsSectionReport(reportResponse, errorCode, error, completion)
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
    
    // MARK: - Office related methods
    
    func getAllOfficesData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processAllOfficesSectionReport(data, 200, error, completion)
            }
        }
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processAllOfficesSectionReport(reportResponse, errorCode, error, completion)
        }
    }
    
    private func processAllOfficesSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.officeStatus.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allOffices.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            getCachedResponse(for: .getAllOffices) {[weak self] (data, error) in
                if let _ = data {
                    self?.processAllOffices(reportData, data, 200, error, completion)
                }
            }
            apiManager.getAllOffices(generationNumber: generationNumber) { [weak self] (officesResponse, errorCode, error) in
                self?.cacheData(officesResponse, path: .getAllOffices)
                self?.processAllOffices(reportData, officesResponse, errorCode, error, completion)
            }
        } else {
            completion?(errorCode, error)
        }
    }
    
    private func processAllOffices(_ reportData: ReportDataResponse?, _ officesResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            fillAllOfficesData(with: officesResponse, indexes: getDataIndexes(columns: reportData?.meta.widgetsDataSource?.allOffices?.columns) )
        }
        completion?(errorCode, retErr)
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
    
    func getCurrentOffice(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getCurrentOffice { [weak self] (response, errorCode, error) in
            var userPreferencesResponse: UserPreferencesResponse?
            var retErr = error
            if let responseData = response {
                do {
                    userPreferencesResponse = try DataParser.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            if let userPreferencesResponse = userPreferencesResponse {
                self?.selectedOfficeId = Int(userPreferencesResponse.data.preferences?.officeId ?? "")
            }
            completion?(errorCode, retErr)
        }
    }
    
    func setCurrentOffice(officeId: Int, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.setCurrentOffice(officeId: officeId) { [weak self] (response, errorCode, error) in
            if let _ = response, errorCode == 200, error == nil {
                self?.selectedOfficeId = officeId
            }
            completion?(errorCode, error)
        }
    }
    
    // MARK: - Common methods
    
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
        cacheManager.cacheResponse(responseData: data!, requestURI: path.endpoint) { (error) in
            if let error = error {
                print("Function: \(#function), line: \(#line), message: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCachedResponse(for path: CacheManager.path, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        cacheManager.getCachedResponse(requestURI: path.endpoint, completion: completion)
    }
    
}
