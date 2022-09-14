//
//  Utils.swift
//  GTA
//
//  Created by Margarita N. Bock on 24.11.2020.
//

import Foundation

struct USMSettings {
    #if GTA || HelpDeskProd
    static let usmBasicURL = "https://usm.smeanalyticsportal.com/oauth2/openid/v1/authorize"
    #elseif GTADev || HelpDeskDev
    static let usmBasicURL = "https://uat-auth-console.sonymusic.com/oauth2/openid/v1/authorize"
    #else
    static let usmBasicURL = "https://uat-usm.smeanalyticsportal.com/oauth2/openid/v1/authorize"
    #endif
    
    #if GTADev || HelpDeskDev
    static let usmRedirectURL = "https://gtadev.smedsp.com:8888/validate"
    static let usmClientID = "bkYjQ2hKUFJkejY/YytrY3RLUlA"
    static let usmInternalRedirectURL = "https://gtadev.smedsp.com/charts-ui2/#/auth/processor"
    static let usmLogoutURL = "https://gtadev.smedsp.com:8888/logout/oauth2"
    #elseif GTA || HelpDeskProd
    static let usmRedirectURL = "https://gtaapi.smedsp.com:8888/validate"
    static let usmClientID = "MmRCOFFZcT9nKlpxeFNnRjY9MnI"
    static let usmInternalRedirectURL = "https://gta.smedsp.com/charts-ui2/#/auth/processor"
    static let usmLogoutURL = "https://gtaapi.smedsp.com:8888/logout/oauth2"
    #else
    static let usmRedirectURL = "https://gtauatapi.smedsp.com:8888/validate"
    static let usmClientID = "clJ6Jnl5MjVYd0QzK1haQmJ4Kko"
    static let usmInternalRedirectURL = "https://gtauatapi.smedsp.com/charts-ui2/#/auth/processor"
    static let usmLogoutURL = "https://gtauatapi.smedsp.com:8888/logout/oauth2"
    #endif
}

public class Utils: NSObject {
    
    class func dateToString(from date: Date, dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    class func stringToDate(from dateString: String, dateFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        let date = dateFormatter.date(from: dateString)
        return date
    }
    
    class func valueOf(param: String, forURL: URL) -> String? {
        let urlComponents = URLComponents(url: forURL, resolvingAgainstBaseURL: false)
        guard let queryItem = urlComponents?.queryItems?.first(where: { $0.name == param }) else { return nil }
        return queryItem.value
    }
    
    class func stateStr(_ nonceStr: String) -> String {
        let stateParamsDict = ["r": USMSettings.usmInternalRedirectURL, "n": nonceStr, "c": USMSettings.usmClientID];
        guard let stateData = try? JSONSerialization.data(withJSONObject: stateParamsDict, options: []) else { return "" }
        return stateData.base64EncodedString()
    }
}
