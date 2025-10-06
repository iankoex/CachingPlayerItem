//
//  CachingPlayerItemDelegate.swift
//  CachingPlayerItem
//
//  Created by ian on 06/10/2025.
//

import AVKit
import Foundation

actor CachingPlayerItemDelegate: NSObject {
    internal let cacheManager: VideoCacheManager
    internal var urlSession: URLSession?
    internal let url: URL
    internal var loadingRequests: [AVAssetResourceLoadingRequest] = []
    internal var currentDataTask: URLSessionDataTask?

    init(url: URL) {
        self.url = url
        self.cacheManager = VideoCacheManager(for: url)
    }

    deinit {
        print("deinit CachingPlayerItemDelegate")
        invalidate()
    }

    /// Invalidates the player item, finishing any loading requests and canceling downloads.
    public func invalidate() {
        self.loadingRequests.forEach { $0.finishLoading() }
        self.invalidateURLSession()
    }

    internal func invalidateURLSession() {
        currentDataTask?.cancel()
        currentDataTask = nil
        self.urlSession?.invalidateAndCancel()
    }
}
