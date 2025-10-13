//
//  Preloader.swift
//  AudioVisualService
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

/// An actor that manages preloading of video data to improve playback experience.
///
/// The `Preloader` proactively downloads video content to ensure smooth playback
/// and reduce buffering. It works by creating a `CachingAVURLAsset` and loading
/// the `isPlayable` property, which triggers AVFoundation's resource loading
/// mechanism. During this process, video data is cached locally.
///
/// The preloader stops downloading when either:
/// - The video is confirmed playable (ensuring minimal data for smooth playback)
/// - The maximum preload size limit is reached (preventing excessive data usage)
///
/// This approach ensures videos can start playing quickly while respecting data limits.
///
/// ## Usage
///
/// ```swift
/// let preloader = Preloader(preloadSize: 5 * 1024 * 1024) // 5MB limit
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
/// - Note: It conforms to `AudioVisualServiceDelegate` to monitor caching progress.
@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
public actor Preloader: AudioVisualServiceDelegate {
    /// The maximum number of bytes to preload for each video.
    ///
    /// This limit prevents excessive data usage by capping the amount of
    /// content downloaded during preloading. When this limit is reached,
    /// preloading stops even if the video isn't fully playable yet.
    /// A typical value is 5MB (5 * 1024 * 1024).
    let preloadSize: Int

    /// A dictionary tracking active preloading tasks for each URL.
    private var preloadingTasks: [URL: Task<Void, Error>] = [:]

    /// Creates a new preloader with the specified preload size limit.
    ///
    /// - Parameter preloadSize: The maximum number of bytes to preload for each video.
    ///                        Defaults to 5MB. Set to a higher value for better
    ///                        buffering but increased data usage.
    public init(preloadSize: Int = 5 * 1024 * 1024) {
        self.preloadSize = preloadSize
    }

    /// Preloads multiple video URLs concurrently.
    ///
    /// This method efficiently starts preloading for multiple videos at once.
    /// Each video will be processed independently, with preloading stopping
    /// when the video becomes playable or the size limit is reached.
    ///
    /// - Parameter urls: An array of video URLs to preload.
    public func preload(_ urls: [URL]) {
        for url in urls {
            preload(url)
        }
    }

    /// Preloads a single video URL.
    ///
    /// This method starts the preloading process for the specified video.
    /// If preloading is already in progress for this URL, the previous
    /// operation is cancelled and a new one begins.
    ///
    /// Preloading will stop when either:
    /// - The video is determined to be playable
    /// - The maximum preload size is reached
    ///
    /// - Parameter url: The URL of the video to preload.
    public func preload(_ url: URL) {
        // Cancel any existing preloading for this URL
        preloadingTasks[url]?.cancel()
        preloadingTasks[url] = nil

        preloadingTasks[url] = Task {
            await startPreloading(url: url)
        }
    }

    /// Cancels any ongoing preloading operation for the given URL.
    ///
    /// This method immediately stops the preloading operation for the specified URL.
    /// The partially downloaded data remains cached and can be used for future playback.
    ///
    /// - Parameter url: The URL for which to cancel the preloading operation.
    public func cancelPreloading(for url: URL) {
        preloadingTasks[url]?.cancel()
        preloadingTasks[url] = nil
    }

    /// Starts the preloading process for a video URL.
    ///
    /// This method creates a `CachingAVURLAsset` and loads the `isPlayable` property,
    /// which triggers AVFoundation's resource loading. During this process, video
    /// data is cached. The method monitors for cancellation and stops when the
    /// video becomes playable.
    ///
    /// - Parameter url: The URL of the video to preload.
    private func startPreloading(url: URL) async {
        guard !Task.isCancelled else { return }

        let asset = CachingAVURLAsset(url: url, serviceDelegate: self)

        let isPlayable = try? await asset.load(.isPlayable)
        if let isPlayable, isPlayable {
            await asset.customResourceLoader.invalidate()
        }
    }

    /// Called when data has been cached for a video asset.
    ///
    /// This delegate method monitors the total bytes cached and cancels preloading
    /// when the maximum preload size is reached, ensuring data usage limits are respected.
    ///
    /// - Parameters:
    ///   - url: The URL of the video asset.
    ///   - totalBytesCached: The total number of bytes cached so far.
    nonisolated public func didCacheData(url: URL, totalBytesCached: Int) {
        if totalBytesCached >= preloadSize {
            Task {
                await cancelPreloading(for: url)
            }
        }
    }
}
