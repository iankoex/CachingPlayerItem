//
//  CacheManager+Helpers.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

extension CacheManager {

    /// Calculates the total size of all cached files in the cache directory.
    ///
    /// This method recursively enumerates all files in the cache directory
    /// and sums their sizes to provide the total cache usage.
    ///
    /// - Returns: The total size in bytes of all cached files.
    public static func totalCacheSize() -> Int {
        var totalCacheSize = 0
        let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        let enumerator = FileManager.default.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: resourceKeys
        )
        guard let enumerator else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }
            guard let isDirProperty = resourceValues.isDirectory, isDirProperty == false else {
                continue
            }
            guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                continue
            }
            totalCacheSize += fileSize
        }
        return totalCacheSize
    }

    /// Deletes all cached data by removing the entire cache directory.
    ///
    /// This method permanently removes the cache directory and all its contents.
    /// Use this method with caution as it will delete all cached video files.
    ///
    /// - Throws: An error if the directory removal operation fails.
    public static func deleteCachedData() throws {
        try FileManager.default.removeItem(at: cacheDirectory)
    }

    /// Updates the modification date of the cached file to the current date.
    ///
    /// This method is used to indicate that the cached file has been recently accessed,
    /// which can help with cache eviction policies based on access time.
    public func touchFile() {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: cacheFileURL.path)
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: codableURLResponseCachePath)
        CacheManager.enforceCacheLimit()
    }

    /// Removes cached files that exceed the maximum retention duration.
    ///
    /// This method automatically cleans up old cached files based on their
    /// modification date. Files older than `maxCacheRetentionDuration` (7 days)
    /// will be deleted to prevent the cache from growing indefinitely.
    ///
    /// Call this method periodically to maintain cache size limits.
    public static func enforceCacheLimit() {
        Task.detached {
            let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .isDirectoryKey]
            let enumerator = FileManager.default.enumerator(
                at: cacheDirectory,
                includingPropertiesForKeys: resourceKeys
            )
            guard let enumerator else { return }

            var cacheFiles: [(fileURL: URL, modificationDate: Date)] = []
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else { continue }
                guard resourceValues.isDirectory == false else { continue }
                guard let modificationDate = resourceValues.contentModificationDate else { continue }
                cacheFiles.append((fileURL, modificationDate))
            }

            let maxCacheRetentionDate = Date().addingTimeInterval(maxCacheRetentionDuration)
            for (fileURL, modificationDate) in cacheFiles where modificationDate > maxCacheRetentionDate {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Failed to remove cached file")
                }
            }
        }
    }
}
