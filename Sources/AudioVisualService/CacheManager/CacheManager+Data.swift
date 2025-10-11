//
//  CacheManager+Data.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

extension CacheManager {
    /// Appends data to the cache file at the specified offset.
    ///
    /// This method writes the provided data to the cache file starting at the given byte offset.
    /// If the cache file doesn't exist, it will be created. The method also updates the
    /// cached data ranges to track which portions of the file have been downloaded.
    ///
    /// - Parameters:
    ///   - data: The data to append to the cache file.
    ///   - offset: The byte offset where the data should be written.
    func appendData(_ data: Data, offset: Int) {
        let fileURL = cacheFileURL
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seek(toOffset: UInt64(offset))
            try fileHandle.write(contentsOf: data)
            let range = NSRange(location: offset, length: data.count)
            let totalBytesCached = updateCachedDataRanges(with: range)
            fileHandle.closeFile()
            serviceDelegate?.didCacheData(url: url, totalBytesCached: totalBytesCached)
            touchFile()
        } catch {
            print(error)
        }
    }

    /// Retrieves cached data for the specified byte range.
    ///
    /// This method attempts to read data from the cache file for the requested range.
    /// It first checks if the requested range is available in the cached data ranges,
    /// then reads the available portion from disk. If the requested range is not
    /// fully cached, it returns only the available portion.
    ///
    /// - Parameter range: The byte range to retrieve from the cache.
    /// - Returns: The cached data for the available portion of the range, or `nil` if no data is available.
    func cachedData(in range: NSRange) -> Data? {
        guard let availableRange = getAvailableRange(for: range) else {
            return nil
        }

        guard let fileHandle = try? FileHandle(forReadingFrom: cacheFileURL) else {
            return nil
        }
        defer { fileHandle.closeFile() }

        // Adjust range length if it goes beyond data bounds
        let adjustedLength = min(availableRange.length, cacheFileSize - availableRange.location)
        do {
            try fileHandle.seek(toOffset: UInt64(availableRange.location))
            let data = try fileHandle.read(upToCount: adjustedLength)
            touchFile()
            return data
        } catch {
            print(error)
        }
        return nil
    }

}
