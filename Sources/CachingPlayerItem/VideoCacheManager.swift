//
//  VideoCacheManager.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import Foundation

/// Manages the local caching of video data for smoother playback and offline access.
public final class VideoCacheManager: Sendable {
    private static var cacheDirectory: URL = URL.cachesDirectory.appending(
        path: "VideoCache",
        directoryHint: .isDirectory
    )
    let fileManager = FileManager.default
    let url: URL

    /// Sets a custom cache directory for all VideoCacheManager instances.
    /// - Parameter directory: The URL of the directory to use for caching.
    public static func setCacheDirectory(_ directory: URL) {
        Self.cacheDirectory = directory
    }

    init(for url: URL) {
        self.url = url

        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: Self.cacheDirectory.path) {
            do {
                try fileManager.createDirectory(
                    at: Self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // Directory creation failed, cache may not work
            }
        }
    }

    func fileSize() -> Int {
        let attributes = try? fileManager.attributesOfItem(
            atPath: cacheFileURL.path()
        )
        return attributes?[.size] as? Int ?? 0
    }

    /// Returns the URL for a cached file based on the original URL.
    var cacheFileURL: URL {
        Self.cacheDirectory.appending(path: url.md5String).appendingPathExtension(url.pathExtension)
    }

    private var codableURLResponseCachePath: String {
        cacheFileURL.appendingPathExtension(for: .json).path(percentEncoded: true)
    }

    /// Stores or appends data for the given URL in the cache directory.
    func appendData(_ data: Data) {
        let fileURL = cacheFileURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Append data if the file already exists
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } catch {
                // Failed to append data to existing file
            }
        } else {
            // Create and write if the file doesn't exist
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                // Failed to write initial data to file
            }
        }
        VideoCacheManager.enforceCacheLimit()
    }

    /// Retrieves cached data for the given URL and byte range.
    func cachedData(in range: NSRange) -> Data? {
        let fileURL = cacheFileURL
        let fileSize = fileSize()
        print("requesting for:", range.location.formatted(.number), "file size:", fileSize.formatted(.number))
        guard range.location < fileSize else { return nil }

        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
            // Failed to open file for reading
            return nil
        }
        defer { fileHandle.closeFile() }

        touchFile()

        // Adjust range length if it goes beyond data bounds
        let adjustedLength = min(range.length, fileSize - range.location)
        fileHandle.seek(toFileOffset: UInt64(range.location))
        return fileHandle.readData(ofLength: adjustedLength)
    }

    func getCachedResponse() -> URLResponse? {
        var value: CodableURLResponse?

        do {
            if let data = fileManager.contents(atPath: codableURLResponseCachePath) {
                value = try JSONDecoder().decode(CodableURLResponse.self, from: data)
            }
        } catch {
            // Decoding failed, return nil
        }
        return value?.urlResponse
    }

    func cacheURLResponse(_ response: URLResponse) {
        let contentLength = getMaxContentRange(from: response)
        let codableResponse = CodableURLResponse.from(response, with: contentLength)
        if fileManager.fileExists(atPath: self.codableURLResponseCachePath) {
            do {
                try fileManager.removeItem(atPath: codableURLResponseCachePath)
            } catch {
                // Failed to remove old response cache
            }
        }
        do {
            let data = try JSONEncoder().encode(codableResponse)
            fileManager.createFile(atPath: codableURLResponseCachePath, contents: data, attributes: nil)
        } catch {
            // Encoding failed, file not created
        }
    }

    var isFullyCached: Bool {
        guard let response = getCachedResponse() else {
            return false
        }
        return response.expectedContentLength == fileSize()
    }

    /// Invalidates the cache for this URL by removing the cached file and response metadata.
    /// - Throws: An error if the file removal fails.
    public func invalidateCache() throws {
        try fileManager.removeItem(at: cacheFileURL)
        if fileManager.fileExists(atPath: codableURLResponseCachePath) {
            try fileManager.removeItem(atPath: codableURLResponseCachePath)
        }
    }

    private func getMaxContentRange(from urlResponse: URLResponse) -> Int? {
        guard let response = urlResponse as? HTTPURLResponse else { return nil }
        guard let contentRange = response.value(forHTTPHeaderField: "Content-Range") else { return nil }
        let components = contentRange.split(separator: "/")
        if components.count == 2, let maxRange = components.last {
            return Int(maxRange)
        }
        return nil
    }
}

private struct CodableURLResponse: Codable {
    var expectedContentLength: Int
    var suggestedFilename: String?
    var mimeType: String?
    var textEncodingName: String?
    var url: URL?

    var urlResponse: URLResponse {
        URLResponse(
            url: url ?? URL(string: "https://example.com")!,
            mimeType: mimeType,
            expectedContentLength: expectedContentLength,
            textEncodingName: textEncodingName
        )
    }

    static func from(_ urlResponse: URLResponse, with desiredExpectedContentLength: Int?) -> CodableURLResponse {
        return CodableURLResponse(
            expectedContentLength: desiredExpectedContentLength ?? Int(urlResponse.expectedContentLength),
            suggestedFilename: urlResponse.suggestedFilename,
            mimeType: urlResponse.mimeType,
            textEncodingName: urlResponse.textEncodingName,
            url: urlResponse.url
        )
    }
}

extension VideoCacheManager {

    /// Returns the total size in bytes of all cached files.
    public static func totalCacheSize() -> Int {
        var totalCacheSize = 0
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]

        guard
            let eor = FileManager.default.enumerator(
                at: Self.cacheDirectory,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
        else {
            return 0
        }

        for case let fileURL as URL in eor {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                let isDirProperty = resourceValues.isDirectory,
                isDirProperty == false,
                let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
            {
                totalCacheSize += fileSize
            }
        }
        return totalCacheSize
    }

    /// Deletes all cached data from the cache directory.
    /// - Throws: An error if the directory removal fails.
    public static func deleteCachedData() throws {
        try FileManager.default.removeItem(at: Self.cacheDirectory)
    }

    private static let maxCacheSize: Int = 500 * 1024 * 1024  // 500MB

    public func touchFile() {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: cacheFileURL.path)
    }

    public static func enforceCacheLimit() {
        let currentSize = totalCacheSize()
        guard currentSize > maxCacheSize else { return }

        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey, .fileSizeKey]
        guard
            let enumerator = FileManager.default.enumerator(
                at: cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])
        else { return }

        var cacheFiles: [(URL, Date, Int)] = []
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                resourceValues.isDirectory == false,
                let modDate = resourceValues.creationDate,
                let fileSize = resourceValues.fileSize
            else { continue }
            cacheFiles.append((fileURL, modDate, fileSize))
        }

        // Sort by modification date (oldest first for LRU approximation)
        cacheFiles.sort { $0.1 < $1.1 }

        var freedSize = 0
        for (url, _, size) in cacheFiles {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                // Failed to remove cached file
            }
            freedSize += size
            if currentSize - freedSize <= maxCacheSize { break }
        }
    }
}
