//
//  ImageCacheManager.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.01.2021.
//

import Foundation

class ImageCacheManager {
    
    private static let syncQueue = DispatchQueue(
       label: "image-urlCache-sync-access"
    )
    
    func getCacheResponse(for url: URL) -> Data? {
        return ImageCacheManager.syncQueue.sync {
            return URLCache.shared.cachedResponse(for: URLRequest(url: url))?.data
        }
    }
    
    func storeCacheResponse(_ response: URLResponse?, data: Data?) {
        guard let _ = response, let _ = data, let responseURL = response?.url else { return }
        let cachedResponse = CachedURLResponse(response: response!, data: data!)
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: responseURL))
    }
    
    func removeCachedData() {
        URLCache.shared.removeAllCachedResponses()
    }
    
}
