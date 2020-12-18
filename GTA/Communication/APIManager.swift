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
    
    enum SectionId: String {
        case home = "5fbbd382cead87a5b8400767"
        case apps = "5fbbd382cead87a5b8400768"
        case serviceDesk = "5fbbd382cead87a5b8400769"
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
    
    func parse<T>(data: Data, decodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) throws -> T? where T : Codable {
        var res: T?
        let decoder = JSONDecoder()
        if let decodingStrategy: JSONDecoder.KeyDecodingStrategy = decodingStrategy {
            decoder.keyDecodingStrategy = decodingStrategy
        }
        do {
            res = try decoder.decode(T.self, from: data)
        } catch {
            throw error
        }
        return res
    }
    
    //MARK: - Homescreen methods
    
    func getGlobalNews(generationNumber: Int, completion: ((_ newsData: GlobalNewsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getGlobalNews(generationNumber: generationNumber), method: "POST", headers: requestHeaders) { (responseData, errorCode, error) in
            var newsDataResponse: GlobalNewsResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    newsDataResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(newsDataResponse, errorCode, retErr)
        }
    }
    
    func getSpecialAlerts(generationNumber: Int, completion: ((_ specialAlertsData: SpecialAlertsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getSpecialAlerts(generationNumber: generationNumber), method: "POST", headers: requestHeaders) { (responseData, errorCode, error) in
            var specialAlertsDataResponse: SpecialAlertsResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    specialAlertsDataResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(specialAlertsDataResponse, errorCode, retErr)
        }
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
    
    func getHelpDeskData(for generationNumber: Int, completion: ((_ serviceDeskResponse: HelpDeskResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getHelpDeskData(generationNumber: generationNumber), method: "POST", headers: requestHeaders) {[weak self] (responseData, errorCode, error) in
            var reportDataResponse: HelpDeskResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    reportDataResponse = try self?.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(reportDataResponse, errorCode, retErr)
        }
    }
    
    func getQuickHelp(generationNumber: Int, completion: ((_ quickHelpData: QuickHelpResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getQuickHelpData(generationNumber: generationNumber), method: "POST", headers: requestHeaders) { (responseData, errorCode, error) in
            var quickHelpDataResponse: QuickHelpResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    quickHelpDataResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(quickHelpDataResponse, errorCode, retErr)
        }
    }
    
    func getTeamContacts(generationNumber: Int, completion: ((_ teamContactsData: TeamContactsResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getTeamContactsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders) { (responseData, errorCode, error) in
            var teamContactsDataResponse: TeamContactsResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    teamContactsDataResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(teamContactsDataResponse, errorCode, retErr)
        }
    }
    //MARK: - My Apps methods
    
    func getMyAppsData(for generationNumber: Int, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getMyAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getAllApps(for generationNumber: Int, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getAllAppsData(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getAppDetailsData(for generationNumber: Int, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getAppDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
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
    
    func getSectionReport(sectionId: String, completion: ((_ reportData: ReportDataResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        let requestParams = ["section_id": sectionId]
        makeRequest(endpoint: .getSectionReport, method: "GET", headers: requestHeaders, params: requestParams) { (responseData, errorCode, error) in
            var reportDataResponse: ReportDataResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    reportDataResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(reportDataResponse, errorCode, retErr)
        }
    }
    
    private func makeRequest(endpoint: requestEndpoint, method: String, headers: [String: String] = [:], params: [String: String] = [:], requestBodyParams: [String: String]? = nil, requestBodyJSONParams: Any? = nil, timeout: Double = 30, completion: RequestCompletion = nil) {
        var requestUrlStr = baseUrl + endpoint.endpoint
        
        var queryStr = ""
        if !params.isEmpty {
            var urlComponents = URLComponents()
            urlComponents.path = baseUrl + endpoint.endpoint
            urlComponents.queryItems = params.map {
                URLQueryItem(name: $0, value: $1.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
            }
            queryStr = urlComponents.query ?? ""
        }
        if !queryStr.isEmpty {
            requestUrlStr += "?"
            requestUrlStr += queryStr
        }
        
        //print("headers =", headers)
        print("requestUrlStr =", requestUrlStr)
        let requestUrl = URL(string: requestUrlStr)!
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
    
//    private func performURLSession(request: URLRequest, completion: RequestCompletion = nil) {
//        let sessionConfig = URLSessionConfiguration.default
//        let session = URLSession(configuration: sessionConfig)
//        let sessionTask = session.dataTask(with: request) {[weak self] (data: Data?, response: URLResponse?, error: Error?) in
//            self?.sessionExpiredHandler.handleExpiredSessionIfNeeded(for: data)
//            var statusCode: Int = 0
//            if let httpResponse = response as? HTTPURLResponse {
//                statusCode = httpResponse.statusCode
//            }
//            completion?(data, statusCode, error)
//        }
//        sessionTask.resume()
//    }
}



