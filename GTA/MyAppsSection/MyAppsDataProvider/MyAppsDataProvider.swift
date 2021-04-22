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
    var appsData: [AppsDataSource] = []
    //private var appImageData: [String : Data?] = [:]
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
    private(set) var tipsAndTricksData = [String : [QuickHelpRow]]()
    private(set) var appContactsData: [String : AppContactsData?] = [:]
        
    // MARK: - Calling methods
    
//    func getAppImageData(from urlString: String, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
//        if let url = URL(string: formImageURL(from: urlString)) {
//            getCachedResponse(for: .getImageDataFor(detailsPath: url.absoluteString), completion: {[weak self] (cachedData, cachedError) in
//                if cachedError == nil {
//                    self?.appImageData[urlString] = cachedData
//                    completion(cachedData, nil)
//                }
//                self?.apiManager.loadImageData(from: url) { (data, response, error) in
//                    if let isContains = self?.appImageData.keys.contains(urlString), isContains, error == nil {
//                        self?.appImageData[urlString] = data
//                    }
//                    self?.cacheData(data, path: .getImageDataFor(detailsPath: url.absoluteString))
//                    DispatchQueue.main.async {
//                        if cachedData == nil ? true : cachedData != data {
//                            if cachedError == nil && error != nil { return }
//                            completion(data, error)
//                        }
//                    }
//                }
//                
//            })
//        } else {
//            completion(nil, ResponseError.noDataAvailable)
//        }
//    }
    
//    func getContactImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
//        getCachedResponse(for: .getImageDataFor(detailsPath: url.absoluteString), completion: {[weak self] (cachedData, error) in
//            if error == nil {
//                completion(cachedData, nil)
//            }
//            self?.apiManager.loadImageData(from: url) { (data, response, error) in
//                self?.cacheData(data, path: .getImageDataFor(detailsPath: url.absoluteString))
//                DispatchQueue.main.async {
//                    completion(data, error)
//                }
//            }
//            
//        })
//    }
    
    func getMyAppsStatus(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processMyAppsStatusSectionReport(data, code, cachedError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.serverError, false)
                    } else {
                        self?.processMyAppsStatusSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
        
        
//        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
//            self?.processMyAppsStatusSectionReport(reportResponse, errorCode, error, isFromCache, completion)
//        }
    }
    
    func getAllApps(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processAllAppsSectionReport(data, code, cachedError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.serverError, false)
                    } else {
                        self?.processAllAppsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    func getAppDetailsData(for app: String?, completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processAppDetailsSectionReport(app, data, code, cachedError, true, { (responseData, code, error, _)  in
                if error == nil {
                    completion?(responseData, code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    if let _ = error {
                        completion?(nil, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.processAppDetailsSectionReport(app, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
        
//        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
//            self?.processAppDetailsSectionReport(app, reportResponse, errorCode, error, isFromCache, completion)
//        }
    }
    
    func getAppContactsData(for app: String?, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processAppContactsSectionReport(app, data, code, cachedError, true, { (dataWasChanged, code, error, _) in
                if error == nil {
                    completion?(dataWasChanged, code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    if let _ = error {
                        completion?(dataWasChanged, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.processAppContactsSectionReport(app, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
//        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache)  in
//            self?.processAppContactsSectionReport(app, reportResponse, errorCode, error, isFromCache, completion)
//        }
    }
    
    func getAppTipsAndTricks(for app: String?, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleAppTipsAndTricksSectionReport(app, data, code, cachedError, true, { (dataWasChanged, code, error, _) in
                if error == nil {
                    completion?(dataWasChanged, code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleAppTipsAndTricksSectionReport(app, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleAppTipsAndTricksSectionReport(_ appName: String?, _ sectionReport: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: sectionReport)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appTipsAndTricks.rawValue }?.generationNumber
        let detailsPath = appName ?? ""
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getAppTipsAndTricks(detailsPath: detailsPath)) {[weak self] (data, error) in
                    self?.handleAppTipsAndTricks(appName: detailsPath, reportData, true, data, errorCode, error, completion: completion)
                }
                return
            }
            if detailsPath.isEmptyOrWhitespace() {
                completion?(false, 0, ResponseError.commonError, fromCache)
                return
            }
            apiManager.getAppTipsAndTricks(for: generationNumber!, appName: detailsPath, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppTipsAndTricks(detailsPath: detailsPath))
                self?.handleAppTipsAndTricks(appName: detailsPath, reportData, false, data, errorCode, error, completion: completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                if generationNumber == 0 {
                    tipsAndTricksData[appName ?? ""]?.removeAll()
                }
                completion?(false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(false, 0, ResponseError.commonError, fromCache)
        }
    }
    
    private func handleAppTipsAndTricks(appName: String, _ reportData: ReportDataResponse?, _ fromCache: Bool, _ tipsAndTricksData: Data?, _ errorCode: Int, _ error: Error?, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        var tipsAndTricksResponse: AppsTipsAndTricksResponse?
        var retErr = error
        if let responseData = tipsAndTricksData {
            do {
                tipsAndTricksResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        var dataChanged: Bool = false
        if let tipsAndTricksResponse = tipsAndTricksResponse {
            dataChanged = fillQuickHelpData(for: appName, with: tipsAndTricksResponse, isFromCache: fromCache)
            if (tipsAndTricksResponse.data?.first?.value?.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(dataChanged, errorCode, retErr, fromCache)
    }
        
//    private func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
//        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
//            if let _ = data, cachedError == nil {
//                self?.cachedReportData = data
//                completion?(data, 200, cachedError, true)
//            }
//            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
//                self?.cacheData(reportResponse, path: .getSectionReport)
//                var newError = error
//                if let _ = error {
//                    newError = ResponseError.commonError
//                }
//                completion?(reportResponse, errorCode, newError, false)
//            })
//        }
//    }
    
    func activateStatusRefresh(completion: @escaping ((_ isNeedToRefreshStatus: Bool) -> Void)) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) {[weak self] (_) in
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                self?.cacheData(reportResponse, path: .getSectionReport)
                if let cachedReport = self?.parseSectionReport(data: self?.cachedReportData), let serverReport = self?.parseSectionReport(data: reportResponse) {
                    completion(serverReport != cachedReport)
                } else {
                    completion(true)
                }
            })
        }
    }
    
    func getPDFData(appName: String, urlString: String, completion: @escaping ((_ pdfData: Data?, _ code: Int?, _ error: Error?) -> Void)) {
        guard let url = URL(string: formImageURL(from: urlString)) else { return }
        self.apiManager.getPDFData(endpoint: url) { (pdfData, response, error) in
            self.cacheData(pdfData, path: .getAppTipsAndTricksPDF(detailsPath: appName))
            let code = response as? HTTPURLResponse
            if let _ = error {
                completion(pdfData, code?.statusCode, ResponseError.serverError)
            } else {
                completion(pdfData, 200, nil)
            }
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
            response[index].appImage = formImageURL(from: response[index].appImage)
            let isMyApp = myAppsStatusData?.values?.first(where: {$0.values?[appNameIndex]?.stringValue == info.app_name}) != nil
            if isMyApp {
                myAppsSection.cellData.append(response[index])
            } else {
                otherAppsSection.cellData.append(response[index])
            }
        }
        var result = [AppsDataSource]()
        result.append(myAppsSection)
        result.append(otherAppsSection)
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
        let columns = myAppsResponse?.meta?.widgetsDataSource?.params?.columns
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
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getMyAppsData) {[weak self] (data, error) in
                    //if let _ = data, error == nil {
                        self?.processMyApps(reportData, data, errorCode, error, completion)
                   // }
                }
                return
            }
            apiManager.getMyAppsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), completion: { [weak self] (data, errorCode, error) in
                //let dataWithStatus = self?.addStatusRequest(to: data)
                self?.cacheData(data, path: .getMyAppsData)
                self?.processMyApps(isFromCache: false, reportData, data, errorCode, error, completion)
            })
        } else {
            let err = error == nil ? ResponseError.commonError : error
            if error != nil || generationNumber == 0 {
                completion?(0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(0, err, false)
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
    
    private func isNeedToRemoveStatusForDate(_ date: String) -> Bool {
        let dateFormatter = DateFormatter()        
        dateFormatter.dateFormat = String.comapreDateFormat
        guard var comparingDate = dateFormatter.date(from:date) else { return true }
        comparingDate.addTimeInterval(600)
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
        var isNeedToRemoveStatus = false
        if let date = allAppsResponse?.data?.requestDate, isNeedToRemoveStatusForDate(date), isFromCache {
            isNeedToRemoveStatus = true
        }
        let columns = allAppsResponse?.meta?.widgetsDataSource?.params?.columns
        allAppsResponse?.indexes = getDataIndexes(columns: columns)
        allAppsResponse?.isStatusExpired = isNeedToRemoveStatus
         if let allAppsResponse = allAppsResponse, (allAppsResponse != self.allAppsData || isNeedToRemoveStatus) {
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
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getAllAppsData) {[weak self] (data, error) in
                    //if let _ = data, error == nil {
                    self?.processAllApps(reportData, true, data, errorCode, error, completion)
                    //}
                }
                return
            }
            apiManager.getAllApps(for: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                let dataWithStatus = self?.addStatusRequest(to: data)
                self?.cacheData(dataWithStatus, path: .getAllAppsData)
                self?.processAllApps(reportData, false, dataWithStatus, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(0, ResponseError.commonError, fromCache)
        }
    }
    
    private func processAppContacts(appName: String, _ reportData: ReportDataResponse?, _ appContactsDataResponse: Data?, _ isFromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
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
        var dataWasChanged: Bool = false
        if appContactsData == nil && self.appContactsData[appName] != nil {
        } else if appContactsData != self.appContactsData[appName] {
            self.appContactsData[appName] = appContactsData
        dataWasChanged = true
        }
        completion?(dataWasChanged, errorCode, retErr, isFromCache)
    }
    
    private func processAppContactsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appContacts.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            let contactsPath = app ?? ""
            if fromCache {
                getCachedResponse(for: .getAppContacts(contactsPath: contactsPath)) {[weak self] (data, error) in
//                    if let _ = data, error == nil {
                    self?.processAppContacts(appName: contactsPath, reportData, data, true, errorCode, error, completion)
                    //}
                }
                return
            }
            apiManager.getAppContactsData(for: generationNumber!, appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppContacts(contactsPath: contactsPath))
                self?.processAppContacts(appName: contactsPath, reportData, data, false, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(generationNumber == 0 ? true : false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(false, 0, ResponseError.commonError, fromCache)
        }
    }
    
    private func processAppDetails(_ reportData: ReportDataResponse?, _ appDetailsDataResponse: Data?, _ isFromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ appDetailsData: AppDetailsData?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
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
        let url = formImageURL(from: appDetailsData?.appIcon)
        appDetailsData?.appFullPath = url
        completion?(appDetailsData, errorCode, retErr, isFromCache)
    }
    
    private func processAppDetailsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appDetailsAll.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            let detailsPath = app ?? ""
            if fromCache {
                getCachedResponse(for: .getAppDetails(detailsPath: detailsPath)) {[weak self] (data, error) in
                    self?.processAppDetails(reportData, data, true, errorCode, error, completion)
                }
                return
            }
            apiManager.getAppDetailsData(for: generationNumber!, appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppDetails(detailsPath: detailsPath))
                self?.processAppDetails(reportData, data, false, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(nil, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(nil, 0, ResponseError.commonError,fromCache)
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
    
    private func fillQuickHelpData(for appName: String, with quickHelpResponse: AppsTipsAndTricksResponse, isFromCache: Bool) -> Bool {
        let indexes = getDataIndexes(columns: quickHelpResponse.meta?.widgetsDataSource?.params?.columns)
        var response: AppsTipsAndTricksResponse = quickHelpResponse
        let key = response.data?.keys.first
        if let rows = response.data?.first?.value?.data?.rows, let _ = key {
            for (index, _) in rows.enumerated() {
                if let _ = response.data?[key!] {
                    response.data?[key!]!?.data?.rows?[index].indexes = indexes
                }
            }
        }
        if tipsAndTricksData[appName] != response.data?.first?.value?.data?.rows ?? [] || (!isFromCache && (tipsAndTricksData[appName] ?? []).isEmpty) {
            tipsAndTricksData[appName] = response.data?.first?.value?.data?.rows ?? []
            return true
        }
        return false
    }
    
    func formTipsAndTricksAnswerBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
        var text = base64EncodedText
        if text?.first == " " {
            text?.removeFirst()
        }
        if let encodedText = text, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8), let htmlAttrString = htmlBodyString.htmlToAttributedString {
            
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
        } else {
            if base64EncodedText != nil, Data(base64Encoded: base64EncodedText!) == nil {
                return NSMutableAttributedString(string: base64EncodedText!)
            }
            return nil
        }
    }
    
}

//protocol AppImageDelegate: class {
//    func setImage(with data: Data?, for appName: String?, error: Error?)
//}
