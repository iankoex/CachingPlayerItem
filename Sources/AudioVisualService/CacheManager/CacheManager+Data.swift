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
            print("creating file")
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seek(toOffset: UInt64(offset))
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }

    func cachedData(in range: NSRange) -> Data? {
        let fileURL = cacheFileURL
        print(
            "cache requesting for:", range.location.formatted(.number), "file size:", cacheFileSize.formatted(.number))
        guard range.location < cacheFileSize else { return nil }

        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
            print("Failed to open file for reading")
            return nil
        }
        defer { fileHandle.closeFile() }

        // Adjust range length if it goes beyond data bounds
        let adjustedLength = min(range.length, cacheFileSize - range.location)
        do {
            try fileHandle.seek(toOffset: UInt64(range.location))
            return try fileHandle.read(upToCount: adjustedLength)
        } catch {
            print(error)
        }
        return nil
    }

}
