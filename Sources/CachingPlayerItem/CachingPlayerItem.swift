//
//  CachingPlayerItem.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

public final class CachingPlayerItem: AVPlayerItem, Sendable {
    nonisolated internal let cacheManager: VideoCacheManager
    internal var urlSession: URLSession?
    internal let url: URL
    internal var loadingRequests: [AVAssetResourceLoadingRequest] = []
    internal var currentDataTask: URLSessionDataTask?

    /// Initializes a CachingPlayerItem that caches video data from the given URL.
    /// - Parameter url: The URL of the video to play and cache.
    public init(url: URL) {
        self.url = url
        let urlWithCustomScheme = Self.replaceScheme(of: url, with: "customcache")

        let asset = AVURLAsset(url: urlWithCustomScheme)
        self.cacheManager = VideoCacheManager(for: url)

        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        asset.resourceLoader.setDelegate(self, queue: .global(qos: .userInteractive))
    }

    deinit {
        invalidate()
    }

    /// Invalidates the player item, finishing any loading requests and canceling downloads.
    public func invalidate() {
        self.loadingRequests.forEach { $0.finishLoading() }
        self.invalidateURLSession()
    }

    nonisolated internal func invalidateURLSession() {
        currentDataTask?.cancel()
        currentDataTask = nil
        self.urlSession?.invalidateAndCancel()
    }

    nonisolated static func replaceScheme(of url: URL, with scheme: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url ?? url
    }
}
