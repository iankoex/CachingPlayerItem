//
//  CacheManager+Helpers.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

extension CacheManager {

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

    public static func deleteCachedData() throws {
        try FileManager.default.removeItem(at: cacheDirectory)
    }

    public func touchFile() {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: cacheFileURL.path)
    }

    public static func enforceCacheLimit() {
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
