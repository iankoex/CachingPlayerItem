//
//  ResourceLoader+DataRequest.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate DataRequestRequestMethods

extension ResourceLoader {

    /// Handles a data request by serving cached data or downloading new data.
    ///
    /// This method first checks if the requested data range is available in the cache.
    /// If cached data is found, it's immediately provided to the request.
    /// Otherwise, a network request is initiated to download the required data range.
    ///
    /// - Parameters:
    ///   - loadingRequest: The overall loading request containing this data request.
    ///   - dataRequest: The specific data request with offset and length information.
    /// - Returns: Always returns `true` as the request is handled asynchronously.
    func handleDataRequest(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        dataRequest: AVAssetResourceLoadingDataRequest
    ) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let range = NSRange(location: requestedOffset, length: 1024 * 500)

        if let data = self.cacheManager.cachedData(in: range) {
            dataRequest.respond(with: data)
            loadingRequest.finishLoading()
            return true
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("bytes=\(range.lowerBound)-\(range.upperBound)", forHTTPHeaderField: "Range")

        let task = urlSession.dataTask(with: urlRequest) { data, _, error in
            guard let data, error == nil else {
                loadingRequest.finishLoading(with: error)
                return
            }

            dataRequest.respond(with: data)
            loadingRequest.finishLoading()
            self.cacheManager.appendData(data, offset: requestedOffset)
        }
        task.resume()
        self.pendingRequests[loadingRequest] = task
        return true
    }
}
