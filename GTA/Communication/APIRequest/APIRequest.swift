//
//  APIRequest.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 29.12.2020.
//

import Foundation

public enum ResponseError: Error, Equatable {
    case commonError
    case serverError
    case parsingError
    case noDataAvailable
    case missingFieldError(missingFields: [String])

    var localizedDescription: String {
        switch self {
        case .commonError, .serverError, .parsingError:
            return "Oops, something went wrong"
        case .noDataAvailable:
            return "No data available"
        case .missingFieldError(let missingFields):
            return "\(missingFields) fields are missing"
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
