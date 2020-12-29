//
//  APIManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

typealias RequestCompletion = ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)?

class APIManager: NSObject, URLSessionDelegate {
    private var sessionExpiredHandler: SessionExpiredHandler = SessionExpiredHandler()
    private var networkManager: NetworkManager = NetworkManager()
    
    let baseUrl = "https://gtastageapi.smedsp.com:8888"
    private let accessToken: String?
    
    private enum requestEndpoint {
        case validateToken
        case getSectionReport
        case getGlobalNews(generationNumber: Int)
        case getSpecialAlerts(generationNumber: Int)
        case getHelpDeskData(generationNumber: Int)
        case getQuickHelpData(generationNumber: Int)
        case getTeamContactsData(generationNumber: Int)
        case getMyAppsData(generationNumber: Int)
        case getAllAppsData(generationNumber: Int)
        case getAppDetails(generationNumber: Int)
        
        var endpoint: String {
            switch self {
                case .validateToken: return "/v1/me"
                case .getSectionReport: return "/v3/reports/"
                case .getGlobalNews(let generationNumber): return "/v3/widgets/global_news/data/\(generationNumber)"
                case .getSpecialAlerts(let generationNumber): return "/v3/widgets/special_alerts/data/\(generationNumber)"
                case .getHelpDeskData(let generationNumber): return "/v3/widgets/gsd_profile/data/\(generationNumber)"
                case .getQuickHelpData(let generationNumber): return "/v3/widgets/gsd_quick_help/data/\(generationNumber)"
                case .getTeamContactsData(let generationNumber): return "/v3/widgets/gsd_team_contacts/data/\(generationNumber)"
                case .getMyAppsData(let generationNumber): return "/v3/widgets/my_apps_status/data/\(generationNumber)"
                case .getAllAppsData(let generationNumber): return "/v3/widgets/all_apps/data/\(generationNumber)"
                case .getAppDetails(let generationNumber): return "/v3/widgets/app_details/data/\(generationNumber)"
            }
        }
    }
    
    enum WidgetId: String {
        case globalNews = "global_news"
        case specialAlerts = "special_alerts"
        case gsdProfile = "gsd_profile"
        case gsdQuickHelp = "gsd_quick_help"
        case gsdTeamContacts = "gsd_team_contacts"
        case myApps = "my_apps"
        case myAppsStatus = "my_apps_status"
        case allApps = "all_apps"
        case appDetails = "app_details"
        case productionAlerts = "production_alerts"
    }
    
    init(accessToken: String?) {
        self.accessToken = accessToken
        self.networkManager.delegate = sessionExpiredHandler
    }
    
    //MARK: - Homescreen methods
    
    func getGlobalNews(generationNumber: Int, completion: ((_ newsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getGlobalNews(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getSpecialAlerts(generationNumber: Int, completion: ((_ specialAlertsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getSpecialAlerts(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func loadImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        // loading from cache if it possible
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)) {
            completion(cachedResponse.data, nil)
            return
        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let responseURL = response?.url, let response = response {
                    // saving to cache
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: responseURL))
                }
                completion(data, error)
            }
        }
        dataTask.resume()
    }
    
    //MARK: - Service Desk methods
    
    func getHelpDeskData(for generationNumber: Int, completion: ((_ serviceDeskResponse: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getHelpDeskData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
        
    func getQuickHelp(generationNumber: Int, completion: ((_ quickHelpData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getQuickHelpData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getTeamContacts(generationNumber: Int, completion: ((_ teamContactsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getTeamContactsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    //MARK: - My Apps methods
    
    func getMyAppsData(for generationNumber: Int, username: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": username]
        self.makeRequest(endpoint: .getMyAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getAllApps(for generationNumber: Int, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getAllAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getAppDetailsData(for generationNumber: Int, username: String, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": username, "s2": appName]
        self.makeRequest(endpoint: .getAppDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    
//    func getAppsServiceAlert(for generationNumber: Int, completion: ((_ serviceDeskResponse: MyAppsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
//        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
//        self.makeRequest(endpoint: .getSpecialAlerts(generationNumber: generationNumber), method: "POST", headers: requestHeaders) {[weak self] (responseData, errorCode, error, isResponseSuccessful) in
//            var reportDataResponse: MyAppsResponse?
//            var retErr = error
//            if let responseData = responseData {
//                do {
//                    reportDataResponse = try self?.parse(data: responseData)
//                } catch {
//                    retErr = error
//                }
//            }
//            completion?(reportDataResponse, errorCode, retErr)
//        }
//    }
    
    //MARK: - Common methods
    
    func validateToken(token: String, completion: ((_ tokenData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": token]
        makeRequest(endpoint: .validateToken, method: "GET", headers: requestHeaders, completion: completion)
    }
    
    func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getSectionReport, method: "GET", headers: requestHeaders, completion: completion)
    }
    
    private func makeRequest(endpoint: requestEndpoint, method: String, headers: [String: String] = [:], params: [String: String] = [:], requestBodyParams: [String: String]? = nil, requestBodyJSONParams: Any? = nil, timeout: Double = 30, completion: RequestCompletion = nil) {
        
        let apiRequest = APIRequest(baseUrl: baseUrl, endpoint: endpoint.endpoint, headers: headers, params: params, requestBodyParams: requestBodyParams, requestBodyJSONParams: requestBodyJSONParams)
        guard let requestUrl = apiRequest.requestUrl else {
            completion?(nil, 0, ResponseError.commonError)
            return
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        for (param, value) in headers {
            request.setValue(value, forHTTPHeaderField: param)
        }
        if !headers.keys.contains("Content-Type") {
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("UTF-8", forHTTPHeaderField:"charset")
        
        if method == "POST" {
            if requestBodyParams != nil {
                var requestBodyStr = ""
                for (param, value) in requestBodyParams! {
                    if requestBodyStr.count > 0 {
                        requestBodyStr = requestBodyStr + "&"
                    }
                    requestBodyStr = requestBodyStr + param + "=" + (value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")
                }
                let requestBodyData = requestBodyStr.data(using: .utf8)
                request.httpBody = requestBodyData
            } else if requestBodyJSONParams != nil {
                let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBodyJSONParams!, options: [])
                request.httpBody = requestBodyData
            }
        }
        request.timeoutInterval = timeout
        networkManager.performURLRequest(request, completion: completion)
    }
    
}



