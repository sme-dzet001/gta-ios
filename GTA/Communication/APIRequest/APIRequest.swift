//
//  APIRequest.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 29.12.2020.
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
