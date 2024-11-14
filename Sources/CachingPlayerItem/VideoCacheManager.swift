//
//  VideoCacheManager.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//


import Foundation

/// Manages the local caching of video data for smoother playback and offline access.
public final class VideoCacheManager: Sendable {
    private static let cacheDirectory: URL = URL.cachesDirectory.appending(path: "VideoCache", directoryHint: .isDirectory)
    let url: URL
    let identifier: String
    
    init(for url: URL, identifier: String = "") {
        self.url = url
        self.identifier = identifier + "_"
        
        let fileManager = FileManager.default
        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: Self.cacheDirectory.path) {
            try? fileManager.createDirectory(at: Self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func fileSize() -> Int {
        let attributes = try? FileManager.default.attributesOfItem(
            atPath: cacheFileURL.path()
        )
        return attributes?[.size] as? Int ?? 0
    }
    
    /// Returns the URL for a cached file based on the original URL.
    var cacheFileURL: URL {
        Self.cacheDirectory.appending(path: identifier + url.lastPathComponent)
    }
    
    private var codableURLResponseCachePath: String {
        // for some reason `cacheFileURL.appending(path: ".json").path` doesn't work
        Self.cacheDirectory.appending(path: identifier + url.lastPathComponent + ".json").path
    }
    
    /// Stores or appends data for the given URL in the cache directory.
    func appendData(_ data: Data) {
        let fileURL = cacheFileURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Append data if the file already exists
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            // Create and write if the file doesn't exist
            try? data.write(to: fileURL, options: .atomic)
            print("as you append data think about when the user seeks to a position in the video, will you still append data to end of file?")
        }
    }
    
    /// Retrieves cached data for the given URL and byte range.
    func cachedData(in range: NSRange) -> Data? {
        let fileURL = cacheFileURL
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }
        
        // Check if the requested range is valid
        guard range.location < fileData.count else { return nil }
        
        // Adjust range length if it goes beyond data bounds
        let adjustedLength = min(range.length, fileData.count - range.location)
        return fileData.subdata(in: range.location..<(range.location + adjustedLength))
    }
    
    func getCachedResponse() -> URLResponse? {
        var value: CodableURLResponse?
        do {
            if let data = FileManager.default.contents(atPath: codableURLResponseCachePath) {
                value = try JSONDecoder().decode(CodableURLResponse.self, from: data)
            }
        } catch {
            print("Cache: CodableURLResponse from disk could not be decoded")
        }
        return value?.urlResponse
    }
    
    func cacheURLResponse(_ response: URLResponse) {
        let contentLength = getMaxContentRange(from: response)
        let codableResponse = CodableURLResponse.from(response, with: contentLength)
        if FileManager.default.fileExists(atPath: self.codableURLResponseCachePath) == false {
            try? FileManager.default.removeItem(atPath: codableURLResponseCachePath)
        }
        do {
            let data = try JSONEncoder().encode(codableResponse)
            FileManager.default.createFile(atPath: codableURLResponseCachePath, contents: data, attributes: nil)
        } catch {
            print("Cache: Error while encoding CodableURLResponse")
        }
    }
    
    var isFullyCached: Bool {
        guard let response = getCachedResponse() else {
            return false
        }
        return response.expectedContentLength == fileSize()
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

fileprivate struct CodableURLResponse: Codable {
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

public extension VideoCacheManager {
    
    static func totalCacheSize() -> Int {
        var totalCacheSize = 0
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
        
        guard let eor = FileManager.default.enumerator(
            at: Self.cacheDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in eor {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
               let isDirProperty = resourceValues.isDirectory,
               isDirProperty == false,
               let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalCacheSize += fileSize
            }
        }
        return totalCacheSize
    }
    
    static func deleteCachedData() throws {
        try FileManager.default.removeItem(at: Self.cacheDirectory)
    }
}
