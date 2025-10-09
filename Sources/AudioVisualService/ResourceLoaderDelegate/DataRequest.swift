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
        let cachedFileSize = self.cacheManager.cacheFileSize
        let requestedOffset = Int(dataRequest.requestedOffset)

        if cachedFileSize > requestedOffset {
            let range = NSRange(location: requestedOffset, length: cachedFileSize + 2)
            if let data = self.cacheManager.cachedData(in: range) {
                dataRequest.respond(with: data)
                loadingRequest.finishLoading()
                return true
            }
        }

        let requestedLength = dataRequest.requestedLength
        let endOffset = requestedOffset + requestedLength - 1
        let range = NSRange(location: requestedOffset, length: 1024 * 500)

        print(
            "ResourceLoader requesting for data at", range.lowerBound.formatted(.number),
            range.upperBound.formatted(.number))

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
            print("cache size of ", self.cacheManager.cacheFileSize.formatted(.number))
        }
        task.resume()
        self.pendingRequests[loadingRequest] = task
        return true
    }
}
