//
//  APIManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

public enum ResponseError: Error {
    case commonError

    var localizedDescription: String {
        switch self {
        case .commonError:
            return "Oops, something went wrong"
        }
    }
}

struct APIRequest {
    var baseUrl: String
    var endpoint: String
    var headers: [String: String] = [:]
    var params: [String: String] = [:]
    var requestBodyParams: [String: String]? = nil
    var requestBodyJSONParams: Any? = nil
    
    var requestUrl: URL? {
        get {
            var requestUrlStr = baseUrl + endpoint
            
            var queryStr = ""
            if !params.isEmpty {
                var urlComponents = URLComponents()
                urlComponents.path = baseUrl + endpoint
                urlComponents.queryItems = params.map {
                    URLQueryItem(name: $0, value: $1.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
                }
                queryStr = urlComponents.query ?? ""
            }
            if !queryStr.isEmpty {
                requestUrlStr += "?"
                requestUrlStr += queryStr
            }
            
            return URL(string: requestUrlStr)
        }
    }
    
    private func cachedRequestURI(endpoint: String, params: [String: Any]) -> String {
        var queryStr = "?"
        for paramName in params.keys.sorted() {
            if let strVal = params[paramName] as? String {
                queryStr += paramName + "=" + strVal
            } else if let strArrVal = params[paramName] as? [String] {
                for strArrItem in strArrVal {
                    queryStr += paramName + "=" + strArrItem
                }
            } else if let dictArrVal = params[paramName] as? [[String: Any]] {
                for dictArrItem in dictArrVal {
                    queryStr += paramName + ":{"
                    for paramName2 in dictArrItem.keys.sorted() {
                        if let strVal = dictArrItem[paramName2] as? String {
                            queryStr += paramName2 + "=" + strVal
                        }
                    }
                    queryStr += "}"
                }
            } else {
                print("cache error")
            }
        }
        return baseUrl + endpoint + (queryStr.count > 1 ? queryStr : "")
    }
    
    var cachedRequestUri: String {
        get {
            var cachedResponseURIComponents: [String: Any] = [:]
            if let aVal = requestBodyParams {
                cachedResponseURIComponents = aVal.merging(params) { (_, new) in new }
            } else if let aVal = requestBodyJSONParams as? [String: Any] {
                cachedResponseURIComponents = aVal.merging(params) { (_, new) in new }
            } else if let aVal = requestBodyJSONParams as? [Any] {
                cachedResponseURIComponents = ["_Array": aVal].merging(params) { (_, new) in new }
            } else {
                cachedResponseURIComponents = params
            }
            return cachedRequestURI(endpoint: endpoint, params: cachedResponseURIComponents)
        }
    }
}

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
        makeRequest(endpoint: .getGlobalNews(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: completion, completion: completion)
    }
    
    func getSpecialAlerts(generationNumber: Int, cachedDataCallback: ((_ specialAlertsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ specialAlertsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getSpecialAlerts(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: cachedDataCallback, completion: completion)
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
        self.makeRequest(endpoint: .getHelpDeskData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: completion, completion: completion)
    }
        
    func getQuickHelp(generationNumber: Int, cachedDataCallback: ((_ quickHelpData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ quickHelpData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getQuickHelpData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: cachedDataCallback, completion: completion)
    }
    
    func getTeamContacts(generationNumber: Int, cachedDataCallback: ((_ teamContactsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ teamContactsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getTeamContactsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: cachedDataCallback, completion: completion)
    }
    //MARK: - My Apps methods
    
    func getMyAppsData(for generationNumber: Int, username: String, cachedDataCallback: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": username]
        self.makeRequest(endpoint: .getMyAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, immediateCachedDataCallback: cachedDataCallback, completion: completion)
    }
    
    func getAllApps(for generationNumber: Int, cachedDataCallback: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getAllAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, immediateCachedDataCallback: cachedDataCallback, completion: completion)
    }
    
    func getAppDetailsData(for generationNumber: Int, username: String, appName: String, cachedDataCallback: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": username, "s2": appName]
        self.makeRequest(endpoint: .getAppDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, immediateCachedDataCallback: cachedDataCallback, completion: completion)
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
        makeRequest(endpoint: .validateToken, method: "GET", headers: requestHeaders, cacheResponse: false, forceUpdate: true, completion: completion)
    }
    
    func getSectionReport(cachedDataCallback: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil, completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getSectionReport, method: "GET", headers: requestHeaders, immediateCachedDataCallback: cachedDataCallback, completion: completion)
    }
    
    private func makeRequest(endpoint: requestEndpoint, method: String, headers: [String: String] = [:], params: [String: String] = [:], requestBodyParams: [String: String]? = nil, requestBodyJSONParams: Any? = nil, timeout: Double = 30, cacheResponse: Bool = true, forceUpdate: Bool = false, immediateCachedDataCallback: RequestCompletion = nil, completion: RequestCompletion = nil) {
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
        
        if let immediateCachedDataCallback = immediateCachedDataCallback {
            CacheManager.shared.getCachedResponse(requestURI: apiRequest.cachedRequestUri, completion: { (responseData: Data?, error: Error?) in
                if let data = responseData {
                    immediateCachedDataCallback(data, 200, error)
                }
            })
        }
        
        guard let completion = completion else { return }
        
        networkManager.performURLRequest(request, completion:  { (responseData: Data?, errorCode: Int, error: Error?) in
            DispatchQueue.main.async {
                let completeWithCachedResponseData = responseData == nil && errorCode == 0 && !forceUpdate
                let storeResponseData = errorCode == 200 && error == nil && cacheResponse
                
                if completeWithCachedResponseData {
                    CacheManager.shared.getCachedResponse(requestURI: apiRequest.cachedRequestUri, completion: { (responseData: Data?, error: Error?) in
                        completion(responseData, 200, error)
                    })
                    return
                }
                if storeResponseData, let data = responseData {
                    CacheManager.shared.cacheResponse(responseData: data, requestURI: apiRequest.cachedRequestUri) { (error) in
                        completion(responseData, errorCode, error)
                    }
                    return
                }
                completion(responseData, errorCode, error)
            }
        })
    }
    
}



