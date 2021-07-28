//
//  KeychainManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

func random(_ n: Int) -> String
{
    let a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    var s = ""
    for _ in 0..<n {
        let r = Int(arc4random_uniform(UInt32(a.count)))
        s += String(a[a.index(a.startIndex, offsetBy: r)])
    }
    return s
}

public class KeychainManager: NSObject {
    
    static let keychainPinKey = "KeychainPinKey"
    static let pinVerificationAttemptsCount = 3
    static let usernameKey = "UsernameKey"
    static let tokenKey = "tokenKey"
    static let tokenExpirationDateKey = "tokenExpirationDateKey"
    static let cachePasswordKey = "CachePasswordKey"
    static let pushNotificationTokenKey = "PushNotificationTokenKey"
    static let pushNotificationTokenSentKey = "PushNotificationTokenSentKey"
    
    class func getUsername() -> String? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : usernameKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let res = String(data: retrievedData, encoding: .utf8) else { return nil }
                return res
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func saveUsername(username: String) -> OSStatus?{
        deleteUsername()
        guard let dataToStore = username.data(using: .utf8) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : usernameKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func deleteUsername() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : usernameKey ] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }
    
    class func getToken() -> String? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : tokenKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let res = String(data: retrievedData, encoding: .utf8) else { return nil }
                return res
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func saveToken(token: String) -> OSStatus?{
        deleteToken()
        guard let dataToStore = token.data(using: .utf8) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : tokenKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func deleteToken() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : tokenKey ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    class func getTokenExpirationDate() -> Date? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : tokenExpirationDateKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let res = String(data: retrievedData, encoding: .utf8) else { return nil }
                if let expirationDate = Utils.stringToDate(from: res, dateFormat: "dd.MM.yyyy HH:mm:ss") {
                    return expirationDate
                } else {
                    return Utils.stringToDate(from: res, dateFormat: "dd.MM.yyyy h:mm:ss a")
                }
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func saveTokenExpirationDate(tokenExpirationDate: Date) -> OSStatus?{
        deleteTokenExpirationDate()
        let tokenExpirationDateString = Utils.dateToString(from: tokenExpirationDate, dateFormat: "dd.MM.yyyy HH:mm:ss")
        guard let dataToStore = tokenExpirationDateString.data(using: .utf8) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : tokenExpirationDateKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func deleteTokenExpirationDate() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : tokenExpirationDateKey ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private class func savePinData(pinData: KeychainPin) -> OSStatus? {
        deletePinData()
        guard let jsonData = try? JSONEncoder().encode(pinData) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : keychainPinKey,
            kSecValueData as String         : jsonData ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func createPin(pin:String) ->  KeychainPin {
        let keychainPin = KeychainPin(pin: pin)
        _ = savePinData(pinData: keychainPin)
        return keychainPin
    }
    
    class func changePin(pin:String) ->  KeychainPin{
        let keychainPin = KeychainPin(pin: pin)
        _ = updatePinData(pinData: keychainPin)
        return keychainPin
    }
    
    class func deletePinData() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : keychainPinKey ] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }
    
    private class func updatePinData(pinData: KeychainPin) -> OSStatus? {
        guard let jsonData = try? JSONEncoder().encode(pinData) else { return nil }
        
        var query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : keychainPinKey,
            kSecValueData as String   : jsonData ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func getPin() -> KeychainPin? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : keychainPinKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let decodedPin = try? JSONDecoder().decode(KeychainPin.self, from: retrievedData) else { return nil }
                return decodedPin
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func isPinValid(pin: String) -> Bool {
        guard var keychainData = getPin() else { return false }
        if keychainData.pinHash == String(pin + keychainData.pinSalt).sha512{
            keychainData.pinVerificationAttemptsLeft = pinVerificationAttemptsCount
            _ = updatePinData(pinData: keychainData)
            return true
        }
        return false
    }
    
    class func decreaseAttemptsLeft() -> Int {
        guard var keychainData = getPin() else { return 0 }
        keychainData.pinVerificationAttemptsLeft -= 1
        if keychainData.pinVerificationAttemptsLeft < 1 {
            deletePinData()
            return 0
        }
        let _ = updatePinData(pinData: keychainData)
        return keychainData.pinVerificationAttemptsLeft
    }
    
    class func getVerificationsAttemptsLeft() -> Int {
        guard let keychainData = getPin() else { return 0 }
        return keychainData.pinVerificationAttemptsLeft
    }
    
    class func resetVerificationAttempts(){
        guard var keychainData = getPin() else { return }
        keychainData.pinVerificationAttemptsLeft = pinVerificationAttemptsCount
        _ = updatePinData(pinData: keychainData)
    }
    
    class func getCachePassword() -> String? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : cachePasswordKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let res = String(data: retrievedData, encoding: .utf8) else { return nil }
                return res
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func saveCachePassword(cachePassword: String) -> OSStatus? {
        deleteCachePassword()
        guard let dataToStore = cachePassword.data(using: .utf8) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : cachePasswordKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func deleteCachePassword() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : cachePasswordKey ] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }
    
    class func getPushNotificationToken() -> String? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : pushNotificationTokenKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let decodedToken = String(data: retrievedData, encoding: .utf8) else { return nil }
                return decodedToken
            }
        } else {
            return nil
        }
        return nil
    }
    
    class func savePushNotificationToken(pushNotificationToken: String) -> OSStatus? {
        deletePushNotificationToken()
        guard let dataToStore = pushNotificationToken.data(using: .utf8) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : pushNotificationTokenKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func isPushNotificationTokenSent() -> Bool {
        guard let _ = getPushNotificationToken() else { return false }
        
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : pushNotificationTokenSentKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef :AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                guard let decodedTokenSentFlag = try? JSONDecoder().decode(Bool.self, from: retrievedData) else { return false }
                return decodedTokenSentFlag
            }
        } else {
            return false
        }
        return false
    }
    
    class func savePushNotificationTokenSent() -> OSStatus? {
        deletePushNotificationTokenSent()
        guard let dataToStore = try? JSONEncoder().encode(true) else { return nil }
        let query = [
            kSecClass as String             : kSecClassGenericPassword as String,
            kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount as String       : pushNotificationTokenSentKey,
            kSecValueData as String         : dataToStore ] as [String : Any]
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func deletePushNotificationToken() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : pushNotificationTokenKey ] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }
    
    class func deletePushNotificationTokenSent() {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : pushNotificationTokenSentKey ] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }
}

struct KeychainPin: Codable {
    var pinVerificationAttemptsLeft: Int
    var pinSalt:String
    let pinHash:String
    
    init(pin:String){
        pinSalt = random(16)
        pinVerificationAttemptsLeft = KeychainManager.pinVerificationAttemptsCount
        pinHash = String(pin + pinSalt).sha512
    }
}
