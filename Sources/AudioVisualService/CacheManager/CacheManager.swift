//
//  CacheManager.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import Foundation

/// A manager that handles local caching of video data for improved playback performance and offline access.
///
/// The `CacheManager` provides functionality to:
/// - Store and retrieve cached video data from disk
/// - Track download progress and cache completeness
/// - Manage cache lifecycle and cleanup
/// - Validate cached content integrity
/// - Notify delegates about caching events and progress
///
/// ## Usage
///
/// ```swift
/// let cacheManager = CacheManager(for: videoURL)
///
/// // Check if video is fully cached
/// if cacheManager.isFullyCached {
///     print("Video is available offline")
/// }
///
/// // Invalidate cache when needed
/// try cacheManager.invalidateCache()
/// ```
@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
public final class CacheManager: Sendable {

    /// The default directory where cached video files are stored.
    ///
    /// This directory is located in the system's caches directory and is automatically
    /// created if it doesn't exist. The directory can be customized using `setCacheDirectory(_:)`.
    static let cacheDirectory: URL = URL.cachesDirectory.appending(
        path: "VideoCache",
        directoryHint: .isDirectory
    )

    /// The delegate that receives notifications about caching events and progress.
    ///
    /// The delegate is notified when data is cached, loading progress updates,
    /// and other caching-related events.
    let serviceDelegate: AudioVisualServiceDelegate?

    /// The cached response metadata for the associated URL.
    ///
    /// This property holds the decoded `CodableURLResponse` containing information
    /// about the video's content length, MIME type, and cached data ranges.
    var cachedCodableURLResponse: CodableURLResponse? = nil

    /// The maximum duration to retain cached files before automatic cleanup.
    ///
    /// Files older than this duration (7 days by default) will be automatically
    /// removed during cache maintenance operations.
    static let maxCacheRetentionDuration: Double = 60 * 60 * 24 * 7  // 7 days

    /// The file manager used for all file system operations.
    let fileManager = FileManager.default

    /// The URL of the video asset being cached.
    let url: URL

    /// Creates a new cache manager for the specified video URL.
    ///
    /// This initializer sets up the cache manager for a specific video URL and
    /// ensures the cache directory exists. The cache directory is created if it
    /// doesn't already exist.
    ///
    /// - Parameters:
    ///   - url: The URL of the video asset to cache.
    ///   - serviceDelegate: An optional delegate to receive caching and loading events.
    init(for url: URL, serviceDelegate: AudioVisualServiceDelegate? = nil) {
        self.url = url
        self.serviceDelegate = serviceDelegate
        if !fileManager.fileExists(atPath: CacheManager.cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: CacheManager.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        print(cacheFileURL)
    }

    /// The size of the cached file in bytes.
    ///
    /// This property returns the actual file size on disk, or 0 if the file doesn't exist
    /// or cannot be accessed. The value is retrieved from the file system's attributes.
    var cacheFileSize: Int {
        let attributes = try? fileManager.attributesOfItem(
            atPath: cacheFileURL.path()
        )
        return attributes?[.size] as? Int ?? 0
    }

    /// The file URL where the cached video data is stored.
    ///
    /// This URL is constructed using an MD5 hash of the video URL to ensure unique
    /// filenames, combined with the original file extension.
    var cacheFileURL: URL {
        CacheManager.cacheDirectory.appending(path: url.md5String).appendingPathExtension(url.pathExtension)
    }

    /// The file path where the cached response metadata is stored.
    ///
    /// This path points to a JSON file containing the `CodableURLResponse` data,
    /// stored alongside the video file with a `.json` extension.
    var codableURLResponseCachePath: String {
        cacheFileURL.deletingPathExtension().appendingPathExtension(for: .json).path(percentEncoded: true)
    }

    /// Invalidates the cache for this URL by removing the cached file and response metadata.
    ///
    /// This method permanently deletes all cached data for the associated URL,
    /// including the video file and any stored response information.
    ///
    /// - Throws: An error if the file removal operation fails.
    public func invalidateCache() throws {
        try fileManager.removeItem(at: cacheFileURL)
        if fileManager.fileExists(atPath: codableURLResponseCachePath) {
            try fileManager.removeItem(atPath: codableURLResponseCachePath)
        }
    }
}
