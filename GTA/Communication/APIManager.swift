//
//  APIManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

class APIManager: NSObject, URLSessionDelegate {
    
    typealias RequestCompletion = ((_ responseData: Data?, _ errorCode: Int, _ error: Error?, _ isResponseSuccessful: Bool) -> Void)?
    
    private let baseUrl = "https://gtastageinternal.smedsp.com:8888"
    private let accessToken: String?
    
    private enum requestEndpoint: String {
        case validateToken
        case getSectionReport
        
        var endpoint: String {
            switch self {
                case .validateToken: return "/v1/me"
                case .getSectionReport: return "/v3/reports/"
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
    }
    
    init(accessToken: String?) {
        self.accessToken = accessToken
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
    
    func getSectionReport(sectionId: String, completion: ((_ reportData: ReportDataResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let requestHeaders = ["Token-Type": "Bearer", "Access-Token": accessToken ?? ""]
        let requestParams = ["section_id": sectionId]
        makeRequest(endpoint: .getSectionReport, method: "GET", headers: requestHeaders, params: requestParams) { (responseData, errorCode, error, isResponseSuccessful) in
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
    
    func validateToken(token: String, completion: ((_ tokenData: AccessTokenValidationResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        makeRequest(endpoint: .validateToken, method: "POST", params: ["token" : token], completion:  { (responseData: Data?, errorCode: Int, error: Error?, isResponseSuccessful: Bool) in
            var tokenValidationResponse: AccessTokenValidationResponse?
            var retErr = error
            if let responseData = responseData {
                do {
                    tokenValidationResponse = try self.parse(data: responseData)
                } catch {
                    retErr = error
                }
            }
            completion?(tokenValidationResponse, errorCode, retErr)
        })
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
        performURLSession(request: request, completion: completion)
    }
    
    private func performURLSession(request: URLRequest, completion: RequestCompletion = nil) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = response as? HTTPURLResponse {
                completion?(data, httpResponse.statusCode, error, httpResponse.statusCode == 200 && data != nil)
            }
        }
        sessionTask.resume()
    }
}
