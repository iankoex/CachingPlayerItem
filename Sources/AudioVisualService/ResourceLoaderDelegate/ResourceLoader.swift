//
//  ResourceLoader.swift
//  CachingPlayerItem
//
//  Created by ian on 06/10/2025.
//

import AVFoundation
import Foundation

/// An actor that manages resource loading for cached video assets.
///
/// The `ResourceLoader` acts as a delegate for `AVAssetResourceLoader` and
/// coordinates between AVFoundation's loading requests and the caching system.
/// It serves cached data when available and manages download operations for
/// uncached content.
///
/// This actor maintains thread safety while handling concurrent loading requests
/// and ensures proper cleanup of network operations.
actor ResourceLoader: NSObject, Sendable {
    /// The cache manager responsible for storing and retrieving cached data.
    nonisolated let cacheManager: CacheManager

    /// The delegate that receives notifications about loading events and progress.
    ///
    /// The delegate is notified when loading starts, finishes, fails, and when
    /// progress updates occur.
    let serviceDelegate: AudioVisualServiceDelegate?

    /// The URL session used for downloading video data.
    let urlSession: URLSession

    /// The URL of the video asset being loaded.
    nonisolated let url: URL

    /// The queue of pending loading requests.
    var loadingRequests: [AVAssetResourceLoadingRequest] = []

    /// A mapping of loading requests to their associated download tasks.
    var pendingRequests: [AVAssetResourceLoadingRequest: URLSessionTask] = [:]

    /// Creates a new resource loader for the specified video URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the video asset to load and cache.
    ///   - serviceDelegate: An optional delegate to receive loading and caching events.
    init(url: URL, serviceDelegate: AudioVisualServiceDelegate? = nil) {
        self.url = url
        self.serviceDelegate = serviceDelegate
        self.cacheManager = CacheManager(for: url, serviceDelegate: serviceDelegate)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }

    deinit {
        invalidate()
    }

    /// Invalidates the resource loader, finishing all pending requests and canceling downloads.
    ///
    /// This method should be called when the associated asset is no longer needed.
    /// It ensures that all loading requests are properly completed and any ongoing
    /// network operations are cancelled. The URL session is also invalidated.
    public func invalidate() {
        let pendingRequests = pendingRequests
        self.loadingRequests.forEach {
            $0.finishLoading()
            pendingRequests[$0]?.cancel()
        }
        urlSession.finishTasksAndInvalidate()
    }
}
