//
//  Utils.swift
//  GTA
//
//  Created by Margarita N. Bock on 24.11.2020.
//

import Foundation

public class Utils: NSObject {
    
    class func dateToString(from date: Date, dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    class func stringToDate(from dateString: String, dateFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.date(from: dateString)
        return date
    }
    
    class func valueOf(param: String, forURL: URL) -> String? {
        let urlComponents = URLComponents(url: forURL, resolvingAgainstBaseURL: false)
        guard let queryItem = urlComponents?.queryItems?.first(where: { $0.name == param }) else { return nil }
        return queryItem.value
    }
}
