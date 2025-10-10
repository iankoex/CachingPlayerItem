//
//  CacheManager+CachedResponse.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

extension CacheManager {
    func getCachedResponse() -> CodableURLResponse? {
        guard let data = fileManager.contents(atPath: codableURLResponseCachePath) else {
            return nil
        }
        let codableURLResponse = try? JSONDecoder().decode(CodableURLResponse.self, from: data)
        cachedCodableURLResponse = codableURLResponse
        return codableURLResponse
    }

    func cacheURLResponse(_ response: URLResponse) {
        let contentLength = getMaxContentRange(from: response)
        let codableResponse = CodableURLResponse.from(response, with: contentLength)
        guard let data = try? JSONEncoder().encode(codableResponse) else {
            return
        }
        // will overwrite the file
        fileManager.createFile(atPath: codableURLResponseCachePath, contents: data, attributes: nil)
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
