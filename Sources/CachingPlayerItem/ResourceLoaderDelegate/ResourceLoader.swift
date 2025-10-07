//
//  ResourceLoader.swift
//  CachingPlayerItem
//
//  Created by ian on 06/10/2025.
//

import AVFoundation
import Foundation

actor ResourceLoader: NSObject, Sendable {
    nonisolated let cacheManager: VideoCacheManager
    let urlSession: URLSession
    nonisolated let url: URL
    var loadingRequests: [AVAssetResourceLoadingRequest] = []
    var pendingRequests: [AVAssetResourceLoadingRequest: URLSessionTask] = [:]

    init(url: URL) {
        self.url = url
        self.cacheManager = VideoCacheManager(for: url)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }

    deinit {
        print("deinit CachingPlayerItemDelegate")
        invalidate()
    }

    /// Invalidates the player item, finishing any loading requests and canceling downloads.
    public func invalidate() {
        self.loadingRequests.forEach {
            $0.finishLoading()
            pendingRequests[$0]?.cancel()
        }
        urlSession.finishTasksAndInvalidate()
    }
}
