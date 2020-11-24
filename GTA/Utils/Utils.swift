//
//  Utils.swift
//  GTA
//
//  Created by Margarita N. Bock on 24.11.2020.
//

import Foundation

public class Utils: NSObject {
    class func valueOf(param: String, forURL: URL) -> String? {
        let urlComponents = URLComponents(url: forURL, resolvingAgainstBaseURL: false)
        guard let queryItem = urlComponents?.queryItems?.first(where: { $0.name == param }) else { return nil }
        return queryItem.value
    }
}
