//
//  KeychainManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 23.11.2020.
//

import Foundation

public class KeychainManager: NSObject {
    
    static let usernameKey = "UsernameKey"
    static let tokenKey = "tokenKey"
    
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
}
