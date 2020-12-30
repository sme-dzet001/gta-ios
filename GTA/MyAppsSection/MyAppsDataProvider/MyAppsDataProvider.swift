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
        
    // MARK: - Calling methods
    
    func getAppsCommonData(completion: ((_ serviceDeskResponse: [AppsDataSource]?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getAllApps { [weak self] (allAppsResponse, allAppsCode, allAppsError) in
            if let _ = allAppsResponse, allAppsError == nil {
                self?.getMyAppsStatus(completion: { (response, code, error) in
                    let commonResponse = self?.crateGeneralResponse(commonResponse: allAppsResponse?.myAppsStatus, appsStatus: response)
                    completion?(commonResponse, code, error)
                })
            } else {
                completion?(nil, allAppsCode, allAppsError)
            }
        }
    }
    
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
    
    func getMyAppsStatus(completion: ((_ myAppsResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processMyAppsStatusSectionReport(reportResponse, errorCode, error, false, completion)
        })
    }
    
    func getAllApps(completion: ((_ allAppsResponse: AllAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processAllAppsSectionReport(data, 200, error, false, completion)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processAllAppsSectionReport(reportResponse, errorCode, error, false, completion)
        })
    }
    
    func getAppDetailsData(for app: String?, completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processAppDetailsSectionReport(app, reportResponse, errorCode, error, false, completion)
        })
    }
    
    func getAppContactsData(for app: String?, completion: ((_ responseData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processAppContactsSectionReport(app, reportResponse, errorCode, error, false, completion)
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
    
    private func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
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
    
    private func crateGeneralResponse(commonResponse: [AppInfo]?, appsStatus: MyAppsResponse?) -> [AppsDataSource]? {
        guard let _ = commonResponse, let _ = appsStatus else { return nil }
        var response = commonResponse
        var myAppsSection = AppsDataSource(sectionName: "My Apps", description: nil, cellData: [], metricsData: nil)
        var otherAppsSection = AppsDataSource(sectionName: "Other Apps", description: "Request Access Permission", cellData: [], metricsData: nil)
        for (index, info) in commonResponse!.enumerated() {
            let appNameIndex = appsStatus?.indexes["app_name"] ?? 0
            let statusIndex = appsStatus?.indexes["status"] ?? 0
            let status = appsStatus!.values?.first(where: {$0.values?[appNameIndex]?.stringValue == info.app_name})
            response![index].appStatus = SystemStatus(status: status?.values?[statusIndex]?.stringValue)
            if let _ = status {
                myAppsSection.cellData.append(response![index])
            } else {
                otherAppsSection.cellData.append(response![index])
            }
        }
        var result = [AppsDataSource]()
        if !myAppsSection.cellData.isEmpty {
            result.append(myAppsSection)
        }
        if !otherAppsSection.cellData.isEmpty {
            result.append(otherAppsSection)
        }
        return result
    }
    
    private func processMyApps(_ reportData: ReportDataResponse?, _ myAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ myAppsResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var myAppsResponse: MyAppsResponse?
        var retErr = error
        if let responseData = myAppsDataResponse {
            do {
                myAppsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = error
            }
        }
        myAppsResponse?.indexes = getDataIndexes(columns: reportData?.meta.widgetsDataSource?.myAppsStatus?.columns)
        completion?(myAppsResponse, errorCode, retErr)
    }
    
    private func processMyAppsStatusSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ myAppsResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.myAppsStatus.rawValue }?.generationNumber
        if let _ = generationNumber {
            getCachedResponse(for: .getMyAppsData) {[weak self] (data, error) in
                if let _ = data {
                    self?.processMyApps(reportData, data!, errorCode, error, completion)
                }
            }
            apiManager.getMyAppsData(for: generationNumber!, username: (KeychainManager.getUsername() ?? ""), completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getMyAppsData)
                self?.processMyApps(reportData, data, errorCode, error, completion)
            })
        } else {
            completion?(nil, errorCode, error)
        }
    }
    
    private func processAllApps(_ reportData: ReportDataResponse?, _ allAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ allAppsResponse: AllAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var allAppsResponse: AllAppsResponse?
        var retErr = error
        if let responseData = allAppsDataResponse {
            do {
                allAppsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = error
            }
        }
        allAppsResponse?.indexes = getDataIndexes(columns: reportData?.meta.widgetsDataSource?.allApps?.columns)
        completion?(allAppsResponse, errorCode, retErr)
    }
    
    private func processAllAppsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ allAppsResponse: AllAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allApps.rawValue }?.generationNumber
        if let _ = generationNumber {
            getCachedResponse(for: .getAllAppsData) {[weak self] (data, error) in
                if let _ = data {
                    self?.processAllApps(reportData, data, errorCode, error, completion)
                }
            }
            apiManager.getAllApps(for: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAllAppsData)
                self?.processAllApps(reportData, data, errorCode, error, completion)
            })
        } else {
            completion?(nil, errorCode, error)
        }
    }
    
    private func processAppContacts(_ reportData: ReportDataResponse?, _ appContactsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ appContactsData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var appContactsData: AppContactsData?
        var retErr = error
        if let responseData = appContactsDataResponse {
            do {
                appContactsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = error
            }
        }
        appContactsData?.indexes = getDataIndexes(columns: reportData?.meta.widgetsDataSource?.appContacts?.columns)
        completion?(appContactsData, errorCode, retErr)
    }
    
    private func processAppContactsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ responseData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appContacts.rawValue }?.generationNumber
        if let _ = generationNumber {
            let contactsPath = (KeychainManager.getUsername() ?? "") + "/" + (app ?? "")
            getCachedResponse(for: .getAppContacts(contactsPath: contactsPath)) {[weak self] (data, error) in
                if let _ = data {
                    self?.processAppContacts(reportData, data, errorCode, error, completion)
                }
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
                retErr = error
            }
        }
        appDetailsData?.indexes = getDataIndexes(columns: reportData?.meta.widgetsDataSource?.appDetails?.columns)
        completion?(appDetailsData, errorCode, retErr)
    }
    
    private func processAppDetailsSectionReport(_ app: String?, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appDetails.rawValue }?.generationNumber
        if let _ = generationNumber {
            let detailsPath = (KeychainManager.getUsername() ?? "") + "/" + (app ?? "")
            getCachedResponse(for: .getAppDetails(detailsPath: detailsPath)) {[weak self] (data, error) in
                if let _ = data {
                    self?.processAppDetails(reportData, data, errorCode, error, completion)
                }
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
