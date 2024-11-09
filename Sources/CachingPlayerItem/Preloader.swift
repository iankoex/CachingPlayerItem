//
//  Preloader.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import Foundation
import AVFoundation

public actor Preloader: Sendable {
    let preloadSize: Int
    var isPreloadingStore: [URL:Bool] = [:]
    
    public init(preloadSize: Int = 5 * 1024 * 1024) {
        self.preloadSize = preloadSize
    }
    
    public func preload(_ urls: [URL]) {
        for url in urls {
            preload(url)
        }
    }
    
    public func preload(_ urls: [(URL, String)]) {
        for url in urls {
            preload(url.0, identifier: url.1)
        }
    }
    
    public func preload(_ url: URL, identifier: String = "") {
        // Check if already preloading or the cache already meets preloadSize
        let isPreloading = isPreloadingStore[url] ?? false
        guard isPreloading == false else { return }
        
        let cacheManager = VideoCacheManager(for: url, identifier: identifier)
        
        // If entire video is cached, skip preload
        if cacheManager.isFullyCached {
            return
        }

        let cachedBytes = cacheManager.fileSize()
        if cachedBytes > preloadSize {
            return
        }
        
        // Start downloading up to preloadSize
        isPreloadingStore[url] = true
        Task {
            await startPreloading(
                url: url,
                from: cachedBytes,
                upTo: preloadSize,
                using: cacheManager
            )
        }
    }
    
    private func startPreloading(url: URL, from offset: Int, upTo bytes: Int, using cacheManager: VideoCacheManager) async {
        var request = URLRequest(url: url)
        request.setValue("bytes=\(offset)-\(bytes - 1)", forHTTPHeaderField: "Range")
        if let (data, response) = try? await createURLSession().data(for: request) {
            cacheManager.cacheURLResponse(response)
            cacheManager.appendData(data)
            self.isPreloadingStore[url] = false
        } else {
            self.isPreloadingStore[url] = false
        }
    }
    
    private func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: nil, delegateQueue: operationQueue)
    }
}
