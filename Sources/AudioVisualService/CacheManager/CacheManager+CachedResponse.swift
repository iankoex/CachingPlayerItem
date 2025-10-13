//
//  CacheManager+CachedResponse.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
extension CacheManager {
    /// Retrieves the cached response metadata for this video.
    ///
    /// This method loads and decodes the `CodableURLResponse` from disk if it exists.
    /// The response contains information about content length, MIME type, and cached ranges.
    /// The loaded response is also cached in memory for future access.
    ///
    /// - Returns: The cached response metadata, or `nil` if no cached response exists.
    func getCachedResponse() -> CodableURLResponse? {
        guard let data = fileManager.contents(atPath: codableURLResponseCachePath) else {
            return nil
        }
        let codableURLResponse = try? JSONDecoder().decode(CodableURLResponse.self, from: data)
        cachedCodableURLResponse = codableURLResponse
        return codableURLResponse
    }

    /// Caches the URL response metadata to disk.
    ///
    /// This method converts the `URLResponse` to a `CodableURLResponse` and saves it
    /// to disk as JSON. The response includes content length, MIME type, and other
    /// metadata needed for proper video playback and caching logic.
    ///
    /// - Parameter response: The URL response to cache.
    func cacheURLResponse(_ response: URLResponse) {
        let contentLength = getMaxContentRange(from: response)
        let codableResponse = CodableURLResponse.from(response, with: contentLength)
        guard let data = try? JSONEncoder().encode(codableResponse) else {
            return
        }
        // will overwrite the file
        fileManager.createFile(atPath: codableURLResponseCachePath, contents: data, attributes: nil)
    }

    /// Extracts the maximum content range from an HTTP response.
    ///
    /// This method parses the "Content-Range" header from HTTP responses to determine
    /// the total content length when partial content is being served.
    ///
    /// - Parameter urlResponse: The URL response to parse.
    /// - Returns: The maximum content length, or `nil` if not available.
    private func getMaxContentRange(from urlResponse: URLResponse) -> Int? {
        guard let response = urlResponse as? HTTPURLResponse else { return nil }
        guard let contentRange = response.value(forHTTPHeaderField: "Content-Range") else { return nil }
        let components = contentRange.split(separator: "/")
        if components.count == 2, let maxRange = components.last {
            return Int(maxRange)
        }
        return nil
    }

    /// Updates the cached response metadata on disk.
    ///
    /// This method overwrites the existing cached response file with updated metadata.
    /// It's typically called when the cached data ranges have changed.
    ///
    /// - Parameter codableResponse: The updated response metadata to cache.
    func updateCachedURLResponse(with codableResponse: CodableURLResponse) {
        if fileManager.fileExists(atPath: self.codableURLResponseCachePath) {
            try? fileManager.removeItem(atPath: codableURLResponseCachePath)
        }
        guard let data = try? JSONEncoder().encode(codableResponse) else {
            return
        }
        fileManager.createFile(atPath: codableURLResponseCachePath, contents: data, attributes: nil)
    }
}
