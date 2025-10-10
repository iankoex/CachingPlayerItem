//
//  CacheManager+Data.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

extension CacheManager {
    func appendData(_ data: Data, offset: Int) {
        let fileURL = cacheFileURL
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seek(toOffset: UInt64(offset))
            try fileHandle.write(contentsOf: data)
            updateCachedDataRanges(with: NSRange(location: offset, length: data.count))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }

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
            return data
        } catch {
            print(error)
        }
        return nil
    }

}
