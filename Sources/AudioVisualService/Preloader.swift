//
//  Preloader.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

/// An actor that manages preloading of video data to improve playback experience.
///
/// The `Preloader` provides functionality to proactively download video content
/// before it's needed for playback. This reduces buffering and improves the
/// user experience, especially for slower network connections.
///
/// ## Usage
///
/// ```swift
/// let preloader = Preloader(preloadSize: 5 * 1024 * 1024) // 5MB
///
/// // Preload a single video
/// preloader.preload(videoURL)
///
/// // Preload multiple videos
/// preloader.preload([videoURL1, videoURL2, videoURL3])
///
/// // Cancel preloading if needed
/// preloader.cancelPreloading(for: videoURL)
/// ```
///
/// - Note: This actor is thread-safe and manages concurrent preloading operations.
public actor Preloader: Sendable {
    /// The maximum number of bytes to preload for each video.
    ///
    /// This limit prevents excessive data usage by capping the amount of
    /// content downloaded during preloading. A typical value is 5MB (5 * 1024 * 1024).
    let preloadSize: Int
    var isPreloadingStore: [URL: Bool] = [:]
    private var preloadingTasks: [URL: Task<Void, Error>] = [:]

    /// Creates a new preloader with the specified preload size limit.
    ///
    /// - Parameter preloadSize: The maximum number of bytes to preload for each video.
    ///                        Defaults to 5MB. Set to a higher value for better
    ///                        buffering but increased data usage.
    public init(preloadSize: Int = 5 * 1024 * 1024) {
        self.preloadSize = preloadSize
    }

    /// Preloads the first `preloadSize` bytes for multiple video URLs.
    ///
    /// This method efficiently preloads multiple videos concurrently.
    /// Videos that are already fully cached or have sufficient preload data
    /// will be skipped automatically.
    ///
    /// - Parameter urls: An array of video URLs to preload.
    public func preload(_ urls: [URL]) {
        for url in urls {
            preload(url)
        }
    }

    /// Preloads the first `preloadSize` bytes of the video at the given URL.
    ///
    /// This method starts an asynchronous download of the video's initial segment.
    /// If preloading is already in progress for this URL, the previous operation
    /// is cancelled and a new one begins.
    ///
    /// The method automatically skips videos that are already fully cached or
    /// have sufficient preload data.
    ///
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

    /// Cancels any ongoing preloading operation for the given URL.
    ///
    /// This method immediately stops the download operation for the specified URL.
    /// The partially downloaded data remains cached and can be used for future playback.
    ///
    /// - Parameter url: The URL for which to cancel the preloading operation.
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
