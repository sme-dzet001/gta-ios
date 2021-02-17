//
//  MyAppsDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 08.12.2020.
//

import Foundation

class MyAppsDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    private var imageCacheManager: ImageCacheManager = ImageCacheManager()
    weak var appImageDelegate: AppImageDelegate?
    var appsData: [AppsDataSource] = []
    private var appImageData: [String : Data?] = [:]
    var allAppsData: AllAppsResponse? {
        didSet {
            appsData = self.crateGeneralResponse() ?? []
        }
    }
    var myAppsStatusData: MyAppsResponse? {
        didSet {
            appsData = self.crateGeneralResponse() ?? []
        }
    }
    
    private var refreshTimer: Timer?
    private var cachedReportData: Data?
        
    // MARK: - Calling methods
    
    func getImageData(for appInfo: [AppInfo]) {
        for info in appInfo {
            if let url = info.appImageData.app_icon {
                getAppImageData(from: url) { (imageData, error) in
                    if info.appImageData.imageData == nil || (imageData != nil && imageData != info.appImageData.imageData) {
                        self.appImageDelegate?.setImage(with: imageData, for: info.app_name, error: error)
                    }
                }
            } else {
                self.appImageDelegate?.setImage(with: nil, for: info.app_name, error: ResponseError.noDataAvailable)
            }
        }
    }
    
    func getAppImageData(from urlString: String, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        guard let url = URL(string: formImageURL(from: urlString)) else { return }
        if let cachedResponse = imageCacheManager.getCacheResponse(for: url) {
            appImageData[urlString] = cachedResponse
            completion(cachedResponse, nil)
            return
        } else {
            apiManager.loadImageData(from: url) { (data, response, error) in
                if self.appImageData.keys.contains(urlString), error == nil {
                    self.appImageData[urlString] = data
                }
                self.imageCacheManager.storeCacheResponse(response, data: data)
                DispatchQueue.main.async {
                    completion(data, error)
                }
            }
        }
    }
    
    func getContactImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        if let cachedResponse = imageCacheManager.getCacheResponse(for: url) {
            completion(cachedResponse, nil)
            return
        } else {
            apiManager.loadImageData(from: url) { (data, response, error) in
                self.imageCacheManager.storeCacheResponse(response, data: data)
                DispatchQueue.main.async {
                    completion(data, error)
                }
            }
        }
    }
    
    func getMyAppsStatus(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
            self?.processMyAppsStatusSectionReport(reportResponse, errorCode, error, isFromCache, completion)
        }
    }
    
    func getAllApps(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
            self?.processAllAppsSectionReport(reportResponse, errorCode, error, isFromCache, completion)
        }
    }
    
    func getAppDetailsData(for app: String?, completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
            self?.processAppDetailsSectionReport(app, reportResponse, errorCode, error, isFromCache, completion)
        }
    }
    
    func getAppContactsData(for app: String?, completion: ((_ responseData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache)  in
            self?.processAppContactsSectionReport(app, reportResponse, errorCode, error, isFromCache, completion)
        }
    }
    
    private func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            if let _ = data, cachedError == nil {
                self?.cachedReportData = data
                completion?(data, 200, cachedError, true)
            }
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                self?.cacheData(reportResponse, path: .getSectionReport)
                var newError = error
                if let _ = error {
                    newError = ResponseError.commonError
                }
                completion?(reportResponse, errorCode, newError, false)
            })
        }
    }
    
    func activateStatusRefresh(completion: @escaping ((_ isNeedToRefreshStatus: Bool) -> Void)) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) {[weak self] (_) in
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                if let cachedReport = self?.parseSectionReport(data: self?.cachedReportData), let serverReport = self?.parseSectionReport(data: reportResponse) {
                    completion(serverReport == cachedReport)
                } else {
                    completion(true)
                }
            })
        }
    }
    
    func invalidateStatusRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
    
    // MARK: - Handling methods
    
    func formatDateString(dateString: String?, initialDateFormat: String) -> String? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = initialDateFormat
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        dateFormatter.dateFormat = "E MMM d'\(date.daySuffix())', yyyy h:mm a"
        let formattedDateString = dateFormatter.string(from: date)
        return formattedDateString
    }
    
    private func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func formContactImageURL(from imagePath: String?) -> String? {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return nil }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    private func getDataIndexes(columns: [ColumnName]?) -> [String : Int] {
        var indexes: [String : Int] = [:]
        guard let columns = columns else { return indexes }
        for (index, column) in columns.enumerated() {
            if let name = column.name {
                indexes[name] = index
            }
        }
        return indexes
    }
    
    private func crateGeneralResponse() -> [AppsDataSource]? {
        guard let allAppsInfo = allAppsData?.myAppsStatus else { return nil }
        guard !allAppsInfo.isEmpty else { return nil }
        var response = allAppsInfo
        var myAppsSection = AppsDataSource(sectionName: "My Apps", description: nil, cellData: [], metricsData: nil)
        var otherAppsSection = AppsDataSource(sectionName: "Other Apps", description: "Request Access Permission", cellData: [], metricsData: nil)
        for (index, info) in allAppsData!.myAppsStatus.enumerated() {
            let appNameIndex = myAppsStatusData?.indexes["app name"] ?? 0
            let isMyApp = myAppsStatusData?.values?.first(where: {$0.values?[appNameIndex]?.stringValue == info.app_name}) != nil
            if appImageData.keys.contains(response[index].appImageData.app_icon ?? ""), let data =  appImageData[response[index].appImageData.app_icon ?? ""] {
                response[index].appImageData.imageData = data
                response[index].appImageData.imageStatus = .loaded
            }
            if isMyApp {
                myAppsSection.cellData.append(response[index])
            } else {
                otherAppsSection.cellData.append(response[index])
            }
        }
        var result = [AppsDataSource]()
        result.append(myAppsSection)
        result.append(otherAppsSection)
        DispatchQueue.main.async {
            let appInfo = result.map({$0.cellData}).reduce([], {$0 + $1})
            self.getImageData(for: appInfo)
        }
        
        return result
    }
    
    private func processMyApps(isFromCache: Bool = true, _ reportData: ReportDataResponse?, _ myAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var myAppsResponse: MyAppsResponse?
        var retErr = error
        if let responseData = myAppsDataResponse {
            do {
                myAppsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        
        if let date = myAppsResponse?.data?.first?.value.data?.requestDate, isNeedToRemoveResponseForDate(date) {
            cacheManager.removeCachedData(for: CacheManager.path.getMyAppsData.endpoint)
            return
        }
        let columns = myAppsResponse?.meta.widgetsDataSource?.params?.columns
        myAppsResponse?.indexes = getDataIndexes(columns: columns)
        if let myAppsResponse = myAppsResponse, self.myAppsStatusData != myAppsResponse {
            self.myAppsStatusData = myAppsResponse
        }
        if (myAppsResponse?.values ?? []).isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(errorCode, retErr, isFromCache)
    }
    
    private func processMyAppsStatusSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.myAppsStatus.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getMyAppsData) {[weak self] (data, error) in
                    if let _ = data, error == nil {
                        self?.processMyApps(reportData, data!, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getMyAppsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), completion: { [weak self] (data, errorCode, error) in
                let dataWithStatus = self?.addStatusRequest(to: data)
                self?.cacheData(dataWithStatus, path: .getMyAppsData)
                self?.processMyApps(isFromCache: false, reportData, dataWithStatus, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error, false)
        }
    }
    
    private func addStatusRequest(to data: Data?) -> Data? {
        guard let _ = data, var stringData = String(data: data!, encoding: .utf8) else { return data }
        if let index = stringData.lastIndex(where: {$0 == "]"}) {
            let nextIndex = stringData.index(after: index)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = String.comapreDateFormat
            let dateString = dateFormatter.string(from: Date())
            stringData.insert(contentsOf: ", \"requestDate\" : \"\(dateString)\"", at: nextIndex)
            return stringData.data(using: .utf8)
        }
        return data
    }
    
    private func isNeedToRemoveResponseForDate(_ date: String) -> Bool {
        let dateFormatter = DateFormatter()        
        dateFormatter.dateFormat = String.comapreDateFormat
        guard var comparingDate = dateFormatter.date(from:date) else { return true }
        comparingDate.addTimeInterval(900)
        return Date() >= comparingDate
    }
    
    private func processAllApps(_ reportData: ReportDataResponse?, _ isFromCache: Bool, _ allAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var allAppsResponse: AllAppsResponse?
        var retErr = error
        if let responseData = allAppsDataResponse {
            do {
                allAppsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = allAppsResponse?.meta.widgetsDataSource?.params?.columns
        allAppsResponse?.indexes = getDataIndexes(columns: columns)
        if let allAppsResponse = allAppsResponse, allAppsResponse != self.allAppsData {
            self.allAppsData = allAppsResponse
        }
        if allAppsResponse == nil || (allAppsResponse?.myAppsStatus ?? []).isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(errorCode, retErr, isFromCache)
    }
    
    private func processAllAppsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allApps.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getAllAppsData) {[weak self] (data, error) in
                    if let _ = data, error == nil {
                        self?.processAllApps(reportData, true, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAllApps(for: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAllAppsData)
                self?.processAllApps(reportData, false, data, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error, fromCache)
        }
    }
    
    private func processAppContacts(_ reportData: ReportDataResponse?, _ appContactsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ appContactsData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var appContactsData: AppContactsData?
        var retErr = error
        if let responseData = appContactsDataResponse {
            do {
                appContactsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = appContactsData?.meta.widgetsDataSource?.params?.columns
        appContactsData?.indexes = getDataIndexes(columns: columns)
        if let contacts = appContactsData?.contactsData, contacts.isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(appContactsData, errorCode, retErr)
    }
    
    private func processAppContactsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ responseData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appContacts.rawValue }?.generationNumber
        if let _ = generationNumber {
            let contactsPath = app ?? ""
            if fromCache {
                getCachedResponse(for: .getAppContacts(contactsPath: contactsPath)) {[weak self] (data, error) in
                    if let _ = data, error == nil {
                        self?.processAppContacts(reportData, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAppContactsData(for: generationNumber!, appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppContacts(contactsPath: contactsPath))
                self?.processAppContacts(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(nil, errorCode, ResponseError.commonError)
                return
            }
            completion?(nil, errorCode, error)
        }
    }
    
    private func processAppDetails(_ reportData: ReportDataResponse?, _ appDetailsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ appDetailsData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var appDetailsData: AppDetailsData?
        var retErr = error
        if let responseData = appDetailsDataResponse {
            do {
                appDetailsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = appDetailsData?.meta.widgetsDataSource?.params?.columns
        appDetailsData?.indexes = getDataIndexes(columns: columns)
        completion?(appDetailsData, errorCode, retErr)
    }
    
    private func processAppDetailsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appDetailsAll.rawValue }?.generationNumber
        if let _ = generationNumber {
            let detailsPath = app ?? ""
            if fromCache {
                getCachedResponse(for: .getAppDetails(detailsPath: detailsPath)) {[weak self] (data, error) in
                    if let _ = data, error == nil {
                        self?.processAppDetails(reportData, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAppDetailsData(for: generationNumber!, appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppDetails(detailsPath: detailsPath))
                self?.processAppDetails(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(nil, errorCode, ResponseError.commonError)
                return
            }
            completion?(nil, errorCode, error)
        }
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

protocol AppImageDelegate: class {
    func setImage(with data: Data?, for appName: String?, error: Error?)
}
