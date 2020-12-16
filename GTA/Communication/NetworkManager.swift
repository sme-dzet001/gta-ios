//
//  NetworkManager.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 16.12.2020.
//

import Foundation

class NetworkManager {
        
    weak var delegate: ExpiredSessionDelegate?
    
    func performURLRequest(_ request: URLRequest, completion: RequestCompletion = nil) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: request) {[weak self] (data: Data?, response: URLResponse?, error: Error?) in
            self?.delegate?.handleExpiredSessionIfNeeded(for: data)
            var statusCode: Int = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            completion?(data, statusCode, error)
        }
        sessionTask.resume()
    }
    
}
