//
//  MyAppsDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 08.12.2020.
//

import Foundation

class MyAppsDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    weak var appImageDelegate: AppImageDelegate?
        
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
    
    private func crateGeneralResponse(commonResponse: [AppInfo]?, appsStatus: MyAppsResponse?) -> [AppsDataSource]? {
        guard let _ = commonResponse, let _ = appsStatus else { return nil }
        var response = commonResponse
        var myAppsSection = AppsDataSource(sectionName: "My Apps", description: nil, cellData: [], metricsData: nil)
        var otherAppsSection = AppsDataSource(sectionName: "Other Apps", description: "Request Access Permission", cellData: [], metricsData: nil)
        for (index, info) in commonResponse!.enumerated() {
            let status = appsStatus!.values?.first(where: {$0.values?[1].stringValue == info.app_name})
            response![index].appStatus = SystemStatus(status: status?.values?[2].stringValue)
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
    
    private func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func getMyAppsStatus(completion: ((_ myAppsResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.apps.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.myAppsStatus.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getMyAppsData(for: generationNumber!, completion: { (data, errorCode, error) in
                    var myAppsResponse: MyAppsResponse?
                    var retErr = error
                    if let responseData = data {
                        do {
                            myAppsResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    completion?(myAppsResponse, errorCode, retErr)
                })
            } else {
                completion?(nil, errorCode, error)
            }
        }
    }
    
    func getAllApps(completion: ((_ allAppsResponse: AllAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.apps.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.myApps.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allApps.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getAllApps(for: generationNumber!, completion: { (data, errorCode, error) in
                    var allAppsResponse: AllAppsResponse?
                    var retErr = error
                    if let responseData = data {
                        do {
                            allAppsResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    completion?(allAppsResponse, errorCode, retErr)
                })
            } else {
                completion?(nil, errorCode, error)
            }
        }
    }
    
    func getAppDetailsData(for app: String?, completion: ((_ responseData: AppDetailsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.apps.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.appDetails.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getAppDetailsData(for: generationNumber!, completion: { (data, errorCode, error) in
                    var appDetailsData: AppDetailsData?
                    var retErr = error
                    if let responseData = data {
                        do {
                            appDetailsData = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    var result = appDetailsData
                    result?.appKey = app
                    completion?(result, errorCode, retErr)
                })
            } else {
                completion?(nil, errorCode, error)
            }
        }
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
    
}

protocol AppImageDelegate: class {
    func setImage(with data: Data?, for appName: String?)
}
