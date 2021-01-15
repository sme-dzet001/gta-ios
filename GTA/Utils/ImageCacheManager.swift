//
//  ImageCacheManager.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.01.2021.
//

import Foundation

class ImageCacheManager {
    
    func getCacheResponse(for url: URL) -> Data? {
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)) {
            return cachedResponse.data
        } else {
            return nil
        }
    }
    
    func storeCacheResponse(_ response: URLResponse?, data: Data?) {
        guard let _ = response, let _ = data, let responseURL = response?.url else { return }
        let cachedResponse = CachedURLResponse(response: response!, data: data!)
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: responseURL))
    }
    
}
