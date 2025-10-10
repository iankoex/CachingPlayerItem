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

    func handleDataRequest(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        dataRequest: AVAssetResourceLoadingDataRequest
    ) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let endOffset = requestedOffset + requestedLength - 1
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
                print(error)
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
