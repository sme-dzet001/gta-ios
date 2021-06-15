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
    
    #if GTADev
    let baseUrl = "https://gtadev.smedsp.com:8888"
    #elseif GTA
    let baseUrl = "https://gtaapi.smedsp.com:8888"
    #else
    let baseUrl = "https://gtastageapi.smedsp.com:8888"
    #endif
    private let accessToken: String?
    
    private enum requestEndpoint {
        case validateToken
        case prolongSession
        case getSectionReport
        case getGlobalNews(generationNumber: Int)
        case getSpecialAlerts(generationNumber: Int)
        case getAllOffices(generationNumber: Int)
        case getCurrentPreferences
        case setCurrentPreferences
        case getHelpDeskData(generationNumber: Int)
        case getQuickHelpData(generationNumber: Int)
        case getTeamContactsData(generationNumber: Int)
        case getMyAppsData(generationNumber: Int)
        case getAllAppsData(generationNumber: Int)
        case getAppDetails(generationNumber: Int)
        case getAppContacts(generationNumber: Int)
        case getGSDStatus(generationNumber: Int)
        case getAppTipsAndTricks(generationNumber: Int)
        //case getAppTipsAndTricksPDF(generationNumber: Int)
        case getCollaborationTeamsContacts(generationNumber: Int)
        case getCollaborationTipsAndTricks(generationNumber: Int)
        case getCollaborationDetails(generationNumber: Int)
        case getCollaborationNews(generationNumber: Int)
        case getCollaborationAppDetails(generationNumber: Int)
        case getGSDTickets//(generationNumber: Int)
        case getGSDTicketComments(generationNumber: Int)
        case getGTTeam(generationNumber: Int)
        case getGlobalOutage(generationNumber: Int)
        case sendPushNotificationsToken
        
        var endpoint: String {
            switch self {
                case .validateToken, .prolongSession, .getCurrentPreferences, .setCurrentPreferences: return "/v1/me"
                case .getSectionReport: return "/v3/reports/"
                case .getGlobalNews(let generationNumber): return "/v3/widgets/global_news/data/\(generationNumber)/detailed"
                case .getSpecialAlerts(let generationNumber): return "/v3/widgets/special_alerts/data/\(generationNumber)/detailed"
                case .getAllOffices(let generationNumber): return "/v3/widgets/all_offices/data/\(generationNumber)/detailed"
                case .getHelpDeskData(let generationNumber): return "/v3/widgets/gsd_profile/data/\(generationNumber)/detailed"
                case .getQuickHelpData(let generationNumber): return "/v3/widgets/gsd_quick_help/data/\(generationNumber)/detailed"
                case .getTeamContactsData(let generationNumber): return "/v3/widgets/gsd_team_contacts/data/\(generationNumber)/detailed"
                case .getMyAppsData(let generationNumber): return "/v3/widgets/my_apps_status/data/\(generationNumber)/detailed"
                case .getAllAppsData(let generationNumber): return "/v3/widgets/all_apps_status/data/\(generationNumber)/detailed"
                case .getAppDetails(let generationNumber): return "/v3/widgets/app_details_all_v1/data/\(generationNumber)/detailed"
                case .getAppContacts(let generationNumber): return "/v3/widgets/app_contacts_all/data/\(generationNumber)/detailed"
                case .getGSDStatus(let generationNumber): return "/v3/widgets/gsd_status/data/\(generationNumber)/detailed"
                case .getAppTipsAndTricks(let generationNumber): return "/v3/widgets/app_tips_and_tricks/data/\(generationNumber)/detailed"
                //case .getAppTipsAndTricksPDF(let generationNumber): return "/v3/widgets/app_details_all_v1/data/\(generationNumber)/detailed"
                case .getCollaborationTeamsContacts(let generationNumber): return "/v3/widgets/collaboration_team_contacts/data/\(generationNumber)/detailed"
                case .getCollaborationTipsAndTricks(let generationNumber): return "/v3/widgets/collaboration_tips_and_tricks/data/\(generationNumber)/detailed"
                case .getCollaborationDetails(let generationNumber): return  "/v3/widgets/collaboration_app_suite_details/data/\(generationNumber)/detailed"
                case .getCollaborationNews(let generationNumber): return  "/v3/widgets/collaboration_news/data/\(generationNumber)/detailed"
                case .getCollaborationAppDetails(let generationNumber): return  "/v3/widgets/collaboration_app_details_v1/data/\(generationNumber)/detailed"
                //case .getGSDTickets(let generationNumber): return "/v3/widgets/gsd_my_tickets/data/\(generationNumber)/detailed"
                case .getGSDTickets: return "/v3/salesforce/tickets/"
                case .getGSDTicketComments(let generationNumber): return "/v3/widgets/gsd_ticket_comments/data/\(generationNumber)/detailed"
                case .getGTTeam(let generationNumber): return "/v3/widgets/management_team/data/\(generationNumber)/detailed"
                case .getGlobalOutage(let generationNumber): return "/v3/widgets/global_alerts/data/\(generationNumber)/detailed"
                case .sendPushNotificationsToken: return "/v1/me/push_token/"
            }
        }
    }
    
    enum WidgetId: String {
        case globalNews = "global_news"
        case specialAlerts = "special_alerts"
        case allOffices = "all_offices"
        case officeStatus = "office_status"
        case gsdProfile = "gsd_profile"
        case gsdQuickHelp = "gsd_quick_help"
        case gsdTeamContacts = "gsd_team_contacts"
        case myApps = "my_apps"
        case gsdTickets = "gsd_my_tickets"
        case gsdComments = "gsd_ticket_comments"
        case myAppsStatus = "my_apps_status"
        case allApps = "all_apps_status"
        case appDetails = "app_details"
        case appDetailsAll = "app_details_all_v1" //"app_details_all"
        case appContacts = "app_contacts_all"
        case productionAlerts = "production_alerts"
        case gsdStatus = "gsd_status"
        case appTipsAndTricks = "app_tips_and_tricks"
        //case appTipsAndTricksPDF = "app_details_all_v1"
        case collaboration = "collaboration_app_suite_details"
        case collaborationTeamsContacts = "collaboration_team_contacts"
        case collaborationTipsAndTricks = "collaboration_tips_and_tricks"
        case collaborationAppDetails = "collaboration_app_details"
        case collaborationAppDetailsV1 = "collaboration_app_details_v1"
        case collaborationNews = "collaboration_news"
        case gTTeam = "management_team"
        case globalAlerts = "global_alerts"
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
    
    func getGlobalAlerts(generationNumber: Int, completion: ((_ specialAlertsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getGlobalOutage(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getAllOffices(generationNumber: Int, completion: ((_ allOfficesData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getAllOffices(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getCurrentPreferences(completion: ((_ preferencesData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getCurrentPreferences, method: "GET", headers: requestHeaders, completion: completion)
    }
    
    func setCurrentPreferences(preferences: String, completion: ((_ preferencesData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        let bodyParams = ["preferences": preferences, "token": (accessToken ?? "")]
        makeRequest(endpoint: .setCurrentPreferences, method: "POST", headers: requestHeaders, requestBodyParams: bodyParams, completion: completion)
    }
    
    func loadImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ response: URLResponse?, _ error: Error?) -> Void)) {
        let session = URLSession.shared
        session.dataTask(with: url, completionHandler: completion).resume()
//        let dataTask = session.dataTask(with: url) { (data, response, error) in
//            //DispatchQueue.main.async {
////                if let data = data, let responseURL = response?.url, let response = response {
////                    // saving to cache
////                    let cachedResponse = CachedURLResponse(response: response, data: data)
////                    URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: responseURL))
////                }
//                completion(data, response, error)
//            //}
//        }
//        dataTask.resume()
    }
    
    func getGTTeamData(generationNumber: Int, completion: ((_ newsData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getGTTeam(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
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
    
    func getGSDStatus(generationNumber: Int, completion: ((_ statusData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .getGSDStatus(generationNumber: generationNumber), method: "POST", headers: requestHeaders, completion: completion)
    }
    
    func getGSDTickets(completion: ((_ statusData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getGSDTickets, method: "GET", headers: requestHeaders, completion: completion)
    }
    
//    func getGSDTickets(generationNumber: Int, userEmail: String, completion: ((_ statusData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
//        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
//        let requestBodyParams = ["s1": userEmail]
//        self.makeRequest(endpoint: .getGSDTickets(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
//    }
    
    func getGSDTicketComments(generationNumber: Int, userEmail: String, ticketNumber: String, completion: ((_ statusData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": userEmail, "s2" : ticketNumber]
        self.makeRequest(endpoint: .getGSDTicketComments(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
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
    
    func getAppDetailsData(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getAppDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getAppContactsData(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getAppContacts(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getAppTipsAndTricks(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getAppTipsAndTricks(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getPDFData(endpoint: URL, completion: @escaping ((_ imageData: Data?, _ response: URLResponse?, _ error: Error?) -> Void)) {
        let session = URLSession.shared
        session.dataTask(with: endpoint, completionHandler: completion).resume()
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
    
    // MARK: - Collaboration methods
    
    func getCollaborationDetails(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getCollaborationDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getCollaborationTeamContacts(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getCollaborationTeamsContacts(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getCollaborationTipsAndTricks(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getCollaborationTipsAndTricks(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getCollaborationAppDetails(for generationNumber: Int, appName: String, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        let requestBodyParams = ["s1": appName]
        self.makeRequest(endpoint: .getCollaborationAppDetails(generationNumber: generationNumber), method: "POST", headers: requestHeaders, requestBodyJSONParams: requestBodyParams, completion: completion)
    }
    
    func getCollaborationNews(for generationNumber: Int, completion: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Content-Type": "application/json", "Token-Type": "Bearer", "Access-Token": self.accessToken ?? ""]
        self.makeRequest(endpoint: .getCollaborationNews(generationNumber: generationNumber), method: "POST", headers: requestHeaders,  completion: completion)
    }
    
    //MARK: - Push notifications
    
    func sendPushNotificationsToken(completion: ((_ tokenData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? "", "Content-Type": "application/x-www-form-urlencoded"]
        let bodyParams = ["device_token_type": "apns", "device_token": KeychainManager.getPushNotificationToken() ?? ""]
        //let bodyParams = ["device_token_type": "apns_sandbox", "device_token": KeychainManager.getPushNotificationToken() ?? ""]
        makeRequest(endpoint: .sendPushNotificationsToken, method: "POST", headers: requestHeaders, requestBodyParams: bodyParams, completion: completion)
    }
    
    //MARK: - Common methods
    
    func validateToken(token: String, completion: ((_ tokenData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": token]
        makeRequest(endpoint: .validateToken, method: "GET", headers: requestHeaders, completion: completion)
    }
    
    func prolongSession(completion: ((_ tokenData: Data?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        makeRequest(endpoint: .prolongSession, method: "GET", headers: requestHeaders, completion: completion)
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



