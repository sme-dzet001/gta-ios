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
    
    func storeCacheResponse(_ response: URLResponse?, data: Data?, url: URL, error: Error?) {
        guard error == nil, let _ = response, let _ = data else { return }
        guard let resp = response as? HTTPURLResponse, resp.statusCode >= 200, resp.statusCode < 300 else { return }
        let cachedResponse = CachedURLResponse(response: response!, data: data!)
        ImageCacheManager.syncQueue.sync {
            URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        }
    }
    
    func removeCachedData() {
        URLCache.shared.removeAllCachedResponses()
    }
    
}

