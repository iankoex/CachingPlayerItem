//
//  CacheManager.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import Foundation

/// Manages the local caching of video data for smoother playback and offline access.
public final class CacheManager: Sendable {

    static var cacheDirectory: URL = URL.cachesDirectory.appending(
        path: "VideoCache",
        directoryHint: .isDirectory
    )

    static let maxCacheRetentionDuration: Double = 60 * 60 * 24 * 7 // 7 days
    let fileManager = FileManager.default
    let url: URL

    init(for url: URL) {
        self.url = url

        if !fileManager.fileExists(atPath: Self.cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: CacheManager.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        print(cacheFileURL)
    }

    var isFullyCached: Bool {
        guard let response = getCachedResponse() else {
            return false
        }
        return response.expectedContentLength == cacheFileSize
    }

    var cacheFileSize: Int {
        let attributes = try? fileManager.attributesOfItem(
            atPath: cacheFileURL.path()
        )
        return attributes?[.size] as? Int ?? 0
    }

    var cacheFileURL: URL {
        CacheManager.cacheDirectory.appending(path: url.md5String).appendingPathExtension(url.pathExtension)
    }

    var codableURLResponseCachePath: String {
        cacheFileURL.appendingPathExtension(for: .json).path(percentEncoded: true)
    }

    /// Invalidates the cache for this URL by removing the cached file and response metadata.
    /// - Throws: An error if the file removal fails.
    public func invalidateCache() throws {
        try fileManager.removeItem(at: cacheFileURL)
        if fileManager.fileExists(atPath: codableURLResponseCachePath) {
            try fileManager.removeItem(atPath: codableURLResponseCachePath)
        }
    }

    public static func setCacheDirectory(_ directory: URL) {
        CacheManager.cacheDirectory = directory
    }
}
