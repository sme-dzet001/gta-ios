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
}
