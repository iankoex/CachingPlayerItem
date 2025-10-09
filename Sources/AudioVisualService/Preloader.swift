//
//  Preloader.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

/// An actor that manages preloading of video data to improve playback experience.
public actor Preloader: Sendable {
    /// The maximum size in bytes to preload for each video.
    let preloadSize: Int
    var isPreloadingStore: [URL: Bool] = [:]
    private var preloadingTasks: [URL: Task<Void, Error>] = [:]

    /// Initializes a Preloader with the specified preload size.
    /// - Parameter preloadSize: The number of bytes to preload (default 5MB).
    public init(preloadSize: Int = 5 * 1024 * 1024) {
        self.preloadSize = preloadSize
    }

    /// Preloads the first `preloadSize` bytes for multiple URLs.
    /// - Parameter urls: An array of video URLs to preload.
    public func preload(_ urls: [URL]) {
        for url in urls {
            preload(url)
        }
    }

    /// Preloads the first `preloadSize` bytes of the video at the given URL.
    /// If already preloading, cancels the previous preload and starts a new one.
    /// - Parameter url: The URL of the video to preload.
    public func preload(_ url: URL) {
        // Cancel any existing preloading for this URL
        preloadingTasks[url]?.cancel()
        preloadingTasks[url] = nil

        let cacheManager = CacheManager(for: url)

        // If entire video is cached, skip preload
        if cacheManager.isFullyCached {
            return
        }

        let cachedBytes = cacheManager.cacheFileSize
        if cachedBytes > preloadSize {
            return
        }

        // Start downloading up to preloadSize
        isPreloadingStore[url] = true
        preloadingTasks[url] = Task {
            defer { self.preloadingTasks[url] = nil }
            await startPreloading(
                url: url,
                from: cachedBytes,
                upTo: preloadSize,
                using: cacheManager
            )
        }
    }

    /// Cancels any ongoing preloading for the given URL.
    /// - Parameter url: The URL for which to cancel preloading.
    public func cancelPreloading(for url: URL) {
        preloadingTasks[url]?.cancel()
        preloadingTasks[url] = nil
        isPreloadingStore[url] = false
    }

    private func startPreloading(
        url: URL,
        from offset: Int,
        upTo bytes: Int,
        using cacheManager: CacheManager
    ) async {
        guard !Task.isCancelled else { return }
        var request = URLRequest(url: url)
        request.setValue("bytes=\(offset)-\(bytes - 1)", forHTTPHeaderField: "Range")
        if let (data, response) = try? await createURLSession().data(for: request) {
            guard !Task.isCancelled else { return }
            cacheManager.cacheURLResponse(response)
            cacheManager.appendData(data, offset: offset)
        }
        self.isPreloadingStore[url] = false
    }

    private func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: nil, delegateQueue: operationQueue)
    }
}
