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
    weak var appImageDelegate: AppImageDelegate?
    var appsData: [AppsDataSource] = []
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
    
        
    // MARK: - Calling methods
    
    func getImageData(for appInfo: [AppInfo]) {
        for info in appInfo {
            if let url = URL(string: formImageURL(from: info.app_icon)) {
                getAppImageData(from: url) { (imageData, _) in
                    self.appImageDelegate?.setImage(with: imageData, for: info.app_name)
                }
            }
        }
    }
    
    private func getAppImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        apiManager.loadImageData(from: url, completion: completion)
    }
    
    func getMyAppsStatus(completion: ((_ errorCode: Int, _ error: Error?, _ isFromServer: Bool) -> Void)? = nil) {
        getSectionReport {[weak self] (reportResponse, errorCode, error, isFromCache) in
            self?.processMyAppsStatusSectionReport(reportResponse, errorCode, error, isFromCache, completion)
        }
    }
    
    func getAllApps(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
        getCachedResponse(for: .getSectionReport) { (data, error) in
            if let _ = data {
                completion?(data, 200, error, true)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            completion?(reportResponse, errorCode, error, false)
        })
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
    
    //    func getAppsServiceAlert(completion: ((_ serviceDeskResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
    //        apiManager.getSectionReport(sectionId: APIManager.SectionId.apps.rawValue) { [weak self] (reportResponse, errorCode, error) in
    //            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.productionAlerts.rawValue }?.generationNumber
    //            if let _ = generationNumber {
    //                self?.apiManager.getAppsServiceAlert(for: generationNumber!, completion: completion)
    //            } else {
    //                completion?(nil, errorCode, error)
    //            }
    //        }
    //    }
    
    // MARK: - Handling methods
    
    func formatDateString(dateString: String?, initialDateFormat: String) -> String? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = initialDateFormat
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        dateFormatter.dateFormat = "HH:mm zzz E d"
        let formattedDateString = dateFormatter.string(from: date)
        return formattedDateString
    }
    
    private func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
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
        guard let allAppsInfo = allAppsData?.myAppsStatus, let _ = myAppsStatusData else { return nil }
        guard !allAppsInfo.isEmpty else { return nil }
        var response = allAppsData?.myAppsStatus
        var myAppsSection = AppsDataSource(sectionName: "My Apps", description: nil, cellData: [], metricsData: nil)
        var otherAppsSection = AppsDataSource(sectionName: "Other Apps", description: "Request Access Permission", cellData: [], metricsData: nil)
        for (index, info) in allAppsData!.myAppsStatus.enumerated() {
            let appNameIndex = myAppsStatusData?.indexes["app name"] ?? 0
            let statusIndex = myAppsStatusData?.indexes["status"] ?? 0
            let status = myAppsStatusData!.values?.first(where: {$0.values?[appNameIndex]?.stringValue == info.app_name})
            response![index].appStatus = SystemStatus(status: status?.values?[statusIndex]?.stringValue)
            if let _ = status {
                myAppsSection.cellData.append(response![index])
            } else {
                otherAppsSection.cellData.append(response![index])
            }
        }
        var result = [AppsDataSource]()
        result.append(myAppsSection)
        result.append(otherAppsSection)
        return result
    }
    
    private func processMyApps(isFromServer: Bool = false, _ reportData: ReportDataResponse?, _ myAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromServer: Bool) -> Void)? = nil) {
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
        let columns = myAppsResponse?.meta.widgetsDataSource?.params?.columns
        myAppsResponse?.indexes = getDataIndexes(columns: columns)
        if let myAppsResponse = myAppsResponse {
            self.myAppsStatusData = myAppsResponse
        }
        if myAppsResponse == nil || (myAppsResponse?.values ?? []).isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(errorCode, retErr, isFromServer)
    }
    
    private func processMyAppsStatusSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromServer: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.myAppsStatus.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getMyAppsData) {[weak self] (data, error) in
                    if let _ = data {
                        self?.processMyApps(reportData, data!, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getMyAppsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getMyAppsData)
                self?.processMyApps(isFromServer: true, reportData, data, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error, false)
        }
    }
    
    private func processAllApps(_ reportData: ReportDataResponse?, _ allAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
        if let allAppsResponse = allAppsResponse {
            self.allAppsData = allAppsResponse
        }
        if allAppsResponse == nil || (allAppsResponse?.myAppsStatus ?? []).isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(errorCode, retErr)
    }
    
    private func processAllAppsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allApps.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getAllAppsData) {[weak self] (data, error) in
                    if let _ = data {
                        self?.processAllApps(reportData, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAllApps(for: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAllAppsData)
                self?.processAllApps(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(errorCode, ResponseError.commonError)
                return
            }
            completion?(errorCode, error)
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
            let contactsPath = (KeychainManager.getUsername() ?? "") + "/" + (app ?? "")
            if fromCache {
                getCachedResponse(for: .getAppContacts(contactsPath: contactsPath)) {[weak self] (data, error) in
                    if let _ = data {
                        self?.processAppContacts(reportData, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAppContactsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppContacts(contactsPath: contactsPath))
                self?.processAppContacts(reportData, data, errorCode, error, completion)
            })
        } else {
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
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appDetails.rawValue }?.generationNumber
        if let _ = generationNumber {
            let detailsPath = (KeychainManager.getUsername() ?? "") + "/" + (app ?? "")
            if fromCache {
                getCachedResponse(for: .getAppDetails(detailsPath: detailsPath)) {[weak self] (data, error) in
                    if let _ = data {
                        self?.processAppDetails(reportData, data, errorCode, error, completion)
                    }
                }
                return
            }
            apiManager.getAppDetailsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), appName: (app ?? ""),  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppDetails(detailsPath: detailsPath))
                self?.processAppDetails(reportData, data, errorCode, error, completion)
            })
        } else {
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
    func setImage(with data: Data?, for appName: String?)
}
