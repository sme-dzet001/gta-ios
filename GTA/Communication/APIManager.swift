//
//  APIManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

class APIManager: NSObject, URLSessionDelegate {
    static let shared = APIManager()
    
    var baseUrl = "https://gtastageapi.smedsp.com:8888"
    
    private enum requestEndpoint: String {
        case validateToken
        
        var endpoint: String {
            switch self {
                case .validateToken: return "/v1/me"
            }
        }
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
    
    func validateToken(token: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        makeRequest(endpoint: .validateToken, method: "POST", params: ["token" : token], completion:  { (responseData: Data?, fromCache: Bool, errorCode: Int, error: Error?, isResponseSuccessful: Bool, curlRequestLine: String) in
            var retErr = error
            if let responseData = responseData {
                do {
                    if let validationResponse: AccessTokenValidationResponse = try self.parse(data: responseData) {
                        _ = KeychainManager.saveUsername(username: validationResponse.data.username)
                        _ = KeychainManager.saveToken(token: validationResponse.data.token)
                    }
                } catch {
                    retErr = error
                }
            }
            if let completion = completion {
                completion(errorCode, retErr)
            }
        })
    }
    
    private func makeRequest(endpoint: requestEndpoint, method: String, headers: [String: String] = [:], params: [String: String] = [:], requestBodyParams: [String: String]? = nil, requestBodyJSONParams: Any? = nil, cacheResponse: Bool = true, forceUpdate: Bool = false, timeout: Double = 30, immediateCachedDataCallback: ((_ responseData: Data?, _ errorCode: Int, _ error: Error?, _ isResponseSuccessful: Bool) -> Void)? = nil, completion: ((_ responseData: Data?, _ fromCache: Bool, _ errorCode: Int, _ error: Error?, _ isResponseSuccessful: Bool, _ curlRequestLine: String) -> Void)? = nil) {
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
            request.setValue(value, forHTTPHeaderField:param)
        }
        if !headers.keys.contains("Content-Type") {
            request.setValue("text/plain", forHTTPHeaderField:"Content-Type")
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
    
    private func performURLSession(request: URLRequest, completion: ((_ responseData: Data?, _ fromCache: Bool, _ errorCode: Int, _ error: Error?, _ isResponseSuccessful: Bool, _ curlRequestLine: String) -> Void)? = nil) {
        let sessionConfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: .main)
        let sessionTask = session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 && error == nil && data != nil {
                    if let completion = completion {
                        completion(data, false, 200, nil, true, "")
                    }
                    return
                }
                if let completion = completion {
                    completion(nil, false, httpResponse.statusCode, error, false, "")
                }
            }
            //TODO: add error handling
            if let completion = completion {
                completion(nil, false, 0, error, false, "")
            }
        }
        sessionTask.resume()
    }
}
