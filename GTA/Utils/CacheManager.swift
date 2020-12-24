//
//  CacheManager.swift
//  GTA
//
//  Created by Margarita N. Bock on 22.12.2020.
//

import Foundation
import CoreData
import UIKit
import RNCryptor

struct CacheManagerConstants {
    static let cacheQueue = "com.sonymusic.gta.cacheQueue" //for working with cache storage
    static let cacheDbQueue = "com.sonymusic.gta.cacheDbQueue" //for working with cache metadata
    static let cacheFolderName = "GTACache"
}

class CacheManager {
    static let shared = CacheManager()
    
    private var cacheQueue: DispatchQueue
    private var cacheDbQueue: DispatchQueue
    
    private var cacheFolderPath: String = ""
    
    private var cachePassword: String?
    
    static let maxBufferSize: Int = 160000
    
    private var buffer: [String: Data] = [:]
    private var bufferKeys: [String] = []
    var bufferSize: Int = 0
    
    init() {
        cacheQueue = DispatchQueue(label: CacheManagerConstants.cacheQueue)
        cacheDbQueue = DispatchQueue(label: CacheManagerConstants.cacheDbQueue)
        
        let fm = FileManager.default
        let cacheFolderURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(CacheManagerConstants.cacheFolderName, isDirectory: true)
        cacheFolderPath = cacheFolderURL.path
        try? fm.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true, attributes: nil)
        
        cachePassword = KeychainManager.getCachePassword()
        if (cachePassword == nil) {
            let cachePasswordData = RNCryptor.randomData(ofLength: 32)
            cachePassword = cachePasswordData.base64EncodedString(options: .lineLength64Characters)
            _ = KeychainManager.saveCachePassword(cachePassword: cachePassword!)
        }
    }
    
    private func getCachePath(requestURI: String, formatVersion: Int32, createIfNotExists: Bool = true, completion: @escaping ((_ path: String?, _ error: Error?) -> Void)) {
        var err: Error? = nil
        var path: String? = nil
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            err = ResponseError.commonError
            completion(nil, err)
            return
        }
        guard !cacheFolderPath.isEmpty else {
            err = ResponseError.commonError
            completion(nil, err)
            return
        }
        var cachedRequestMetadata: CachedRequest? = nil
        let managedContext = appDelegate.databaseContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedRequest")
        fetchRequest.predicate = NSPredicate(format: "uri == %@", requestURI)
        do {
            let results = try managedContext.fetch(fetchRequest) as! [CachedRequest]
            if results.count > 0 {
                cachedRequestMetadata = results[0] as CachedRequest
            }
            if cachedRequestMetadata == nil && createIfNotExists {
                let cachedRequestEntity = NSEntityDescription.entity(forEntityName: "CachedRequest", in: managedContext)!
                cachedRequestMetadata = NSManagedObject(entity: cachedRequestEntity, insertInto: managedContext) as? CachedRequest
                cachedRequestMetadata!.uri = requestURI
                cachedRequestMetadata!.filePath = UUID().description
            }
            if cachedRequestMetadata != nil {
                cachedRequestMetadata!.timestamp = Date()
                cachedRequestMetadata!.formatVersion = formatVersion
            }
            
            path = cachedRequestMetadata?.filePath
            
            try managedContext.save()
        } catch {
            err = error
        }
        DispatchQueue.main.async {
            completion(path, err)
        }
    }
    
    private func writeCache(responseData: Data, path: String, completion: @escaping ((_ error: Error?) -> Void)) {
        var err: Error? = nil
        let encryptedData = RNCryptor.encrypt(data: responseData, withPassword: cachePassword!)
        cacheQueue.async {
            do {
                try encryptedData.write(to: URL(fileURLWithPath: path))
            } catch {
                err = error
            }
            DispatchQueue.main.async {
                completion(err)
            }
        }
    }
    
    private func deleteCacheMetadata(requestURI: String, completion: @escaping ((_ error: Error?) -> Void)) {
        var err: Error? = nil
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            err = ResponseError.commonError
            completion(err)
            return
        }
        let managedContext = appDelegate.databaseContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedRequest")
        fetchRequest.predicate = NSPredicate(format: "uri == %@", requestURI)
        do {
            let results = try managedContext.fetch(fetchRequest) as! [CachedRequest]
            for object in results {
                managedContext.delete(object)
            }
            try managedContext.save()
        } catch {
            err = error
        }
        DispatchQueue.main.async {
            completion(err)
        }
    }
    
    private func deleteCache(path: String, completion: @escaping ((_ error: Error?) -> Void)) {
        var err: Error? = nil
        let fm = FileManager.default
        cacheQueue.async {
            do {
                try fm.removeItem(at: URL(fileURLWithPath: path))
            } catch {
                err = error
            }
            DispatchQueue.main.async {
                completion(err)
            }
        }
    }
    
    private func placeResponseToBuffer(responseData: Data, requestURI: String) {
        if let requestURIComponents = NSURLComponents(string: requestURI) {
            requestURIComponents.query = nil
            if let basicStr = requestURIComponents.string {
                let previouslyCachedKeys = buffer.keys.filter({ $0.hasPrefix(basicStr) })
                for previouslyCachedKey in previouslyCachedKeys {
                    buffer.removeValue(forKey: previouslyCachedKey)
                }
            }
        }
        
        if let oldCache = buffer[requestURI] {
            bufferSize -= oldCache.count
            buffer.removeValue(forKey: requestURI)
            if let bufferKeyIdx = bufferKeys.firstIndex(of: requestURI) {
                bufferKeys.remove(at: bufferKeyIdx)
            }
        }
        while (bufferSize + responseData.count) > CacheManager.maxBufferSize {
            guard let cacheIdToRemove = bufferKeys.first else { break }
            bufferKeys.removeFirst()
            guard let cacheToRemove = buffer[cacheIdToRemove] else { break }
            bufferSize -= cacheToRemove.count
            buffer.removeValue(forKey: cacheIdToRemove)
        }
        buffer[requestURI] = responseData
        bufferSize += responseData.count
        bufferKeys.append(requestURI)
    }
    
    private func getResponseFromBuffer(requestURI: String) -> Data? {
        let bufferedData = buffer[requestURI]
        return bufferedData
    }
    
    func cacheResponse(responseData: Data, requestURI: String, formatVersion: Int32 = 1, completion: @escaping ((_ error: Error?) -> Void)) {
        getCachePath(requestURI: requestURI, formatVersion: formatVersion) { [weak self] (path: String?, err: Error?) in
            if path != nil {
                let cacheFolderURL = URL(fileURLWithPath: (self?.cacheFolderPath ?? ""))
                let fullPath = cacheFolderURL.appendingPathComponent(path!).path
                self?.writeCache(responseData: responseData, path: fullPath, completion: { [weak self] (err: Error?) in
                    if (err != nil) {
                        self?.deleteCache(path: fullPath, completion: { (error: Error?) in
                        })
                        self?.deleteCacheMetadata(requestURI: requestURI, completion: { (error: Error?) in
                        })
                    }
                    self?.placeResponseToBuffer(responseData: responseData, requestURI: requestURI)
                    completion(err)
                })
                return
            }
            if (err != nil) {
                self?.deleteCacheMetadata(requestURI: requestURI, completion: { (error: Error?) in
                })
            }
            completion(err)
        }
    }
    
    func getCachedResponse(requestURI: String, formatVersion: Int32 = 1, completion: @escaping ((_ responseData: Data?, _ error: Error?) -> Void)) {
        var cachedResponseError: Error? = nil
        var responseData: Data? = nil
        if let bufferedData = getResponseFromBuffer(requestURI: requestURI) {
            completion(bufferedData, nil)
            return
        }
        getCachePath(requestURI: requestURI, formatVersion: formatVersion, createIfNotExists: false) { [weak self] (path: String?, err: Error?) in
            cachedResponseError = err
            if path != nil {
                let cacheFolderURL = URL(fileURLWithPath: (self?.cacheFolderPath ?? ""))
                let fullURL = cacheFolderURL.appendingPathComponent(path!)
                do {
                    let encryptedResponseData = try Data(contentsOf: fullURL)
                    responseData = try RNCryptor.decrypt(data: encryptedResponseData, withPassword: self?.cachePassword ?? "")
                } catch {
                    cachedResponseError = error
                }
                if responseData == nil {
                    self?.deleteCache(path: fullURL.path, completion: { (error: Error?) in
                    })
                }
            }
            if responseData == nil {
                self?.deleteCacheMetadata(requestURI: requestURI, completion: { (error: Error?) in
                })
            }
            completion(responseData, cachedResponseError)
        }
    }
    
    func clearCache() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        cacheQueue.async {
            let fm = FileManager.default
            let cachePath = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(CacheManagerConstants.cacheFolderName, isDirectory: true)
            guard let cacheFilePaths = try? fm.contentsOfDirectory(atPath: cachePath.path) else { return }
            for filePath in cacheFilePaths {
                do {
                    try fm.removeItem(atPath: cachePath.appendingPathComponent(filePath).path)
                } catch {
                    print(error)
                }
            }
            let managedContext = appDelegate.databaseContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedRequest")
            let cacheMetadataCleanupRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            DispatchQueue.main.async {
                do {
                    try managedContext.execute(cacheMetadataCleanupRequest)
                    try managedContext.save()
                } catch {
                    print("Failed to perform batch update: \(error)")
                }
            }
        }
    }
}
