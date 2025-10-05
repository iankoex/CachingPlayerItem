//
//  CachingPlayerItem+AVAssetResourceLoaderDelegate.swift
//  CachingPlayerItem
//
//  Created by ian on 04/10/2025.
//

import AVKit
import Foundation

// MARK: AVAssetResourceLoaderDelegate

extension CachingPlayerItem: AVAssetResourceLoaderDelegate {

    /// Intercepts loading requests to serve cached data or download data as needed.
    nonisolated public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        Task {
            await self.addRequest(loadingRequest)
        }
        // Always return true to indicate we will handle this request asynchronously.
        return true
    }

    nonisolated public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        Task {
            await self.removeRequest(loadingRequest)
        }
    }

}

// MARK: - Actor-Safe Methods for Handling Requests

extension CachingPlayerItem {

    private func addRequest(_ request: AVAssetResourceLoadingRequest) {
        // Start the download session if it hasn't started yet.
        if self.urlSession == nil {
            createURLSessionThenLoad()
        }
        loadingRequests.append(request)
        processRequests()  // Process this new request immediately if possible.
    }

    private func removeRequest(_ request: AVAssetResourceLoadingRequest) {
        if let index = loadingRequests.firstIndex(of: request) {
            loadingRequests.remove(at: index)
        }
    }
}

// MARK: AVAssetResourceLoaderDelegate Methods

extension CachingPlayerItem {

    nonisolated private func createURLSessionThenLoad() {
        guard self.urlSession == nil else { return }
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let operationQueue = OperationQueue()
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        createDataTaskAndLoad()
    }

    nonisolated private func createDataTaskAndLoad() {
        var request = URLRequest(url: url)
        // This will cheat the loader to think it is loading some bytes and therefore
        // call resourceLoader with dataRequest which will then be processed from the cache
        let cachedBytes = cacheManager.isFullyCached ? cacheManager.fileSize() - 1 : cacheManager.fileSize()

        // Set range header to resume download from where cache ends
        request.setValue("bytes=\(cachedBytes)-", forHTTPHeaderField: "Range")
        currentDataTask = urlSession?.dataTask(with: request)
        currentDataTask?.resume()
    }

    internal func processRequests() {
        // Use `removeAll(where:)` to process and remove completed requests in one pass.
        loadingRequests.removeAll { request in
            let isHandled = handleLoadingRequest(request)
            if isHandled {
                // Finish the request ONLY if it was fully handled.
                request.finishLoading()
            }
            // The closure returns true to remove the request from the array.
            return isHandled
        }
    }

    /// Returns true if the request is fully handled (should be removed from queue and finished).
    /// False keeps it queued for retry (e.g., after new data arrives).
    nonisolated internal func handleLoadingRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        if let contentRequest = request.contentInformationRequest {
            return handleContentInformationRequest(request)
        } else if let dataRequest = request.dataRequest {
            return handleDataRequest(dataRequest)
        }
        return false
    }

    /// Handles content information request. Returns true only if fully handled (with response available).
    /// Queues if no response yet (will retry after didReceive response).
    nonisolated internal func handleContentInformationRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        print("handling ContentInformationRequest")
        guard let response = cacheManager.getCachedResponse() else {
            print("No cached response yet for ContentInformationRequest - queuing for retry")
            return false  // Keep queued; process again after response cached
        }
        print("ContentInformationRequest with response ok")
        request.contentInformationRequest?.isByteRangeAccessSupported = true
        request.contentInformationRequest?.isEntireLengthAvailableOnDemand = false
        request.contentInformationRequest?.contentType = response.mimeType
        request.contentInformationRequest?.contentLength = response.expectedContentLength
        return true  // Will trigger finishLoading() in caller
    }

    /// Handles data request incrementally. Returns true only if the full range is now fulfilled.
    nonisolated private func handleDataRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let cachedBytes = cacheManager.fileSize()
        let requestRequestedOffset = Int(dataRequest.requestedOffset)
        let requestRequestedLength = dataRequest.requestedLength
        let requestCurrentOffset = Int(dataRequest.currentOffset)
        let requestEndOffset = requestRequestedOffset + requestRequestedLength

        // Already fully responded? (Edge case)
        if requestCurrentOffset >= requestEndOffset {
            print("Data request already complete (currentOffset \(requestCurrentOffset) >= end \(requestEndOffset))")
            return true
        }

        // No data available yet (current beyond cache)
        guard cachedBytes > requestCurrentOffset else {
            print(
                "No data available (cached \(cachedBytes.formatted(.number)) <= current \(requestCurrentOffset.formatted(.number)))"
            )
            return false
        }

        // Compute remaining requested and available
        let requestUnreadLength = requestEndOffset - requestCurrentOffset
        let cachedUnreadLength = cachedBytes - requestCurrentOffset
        let respondLength = min(requestUnreadLength, cachedUnreadLength)

        // Optimization: Skip if no new data to send (though guard ensures >0)
        guard respondLength > 0 else { return false }

        // Respond with available chunk
        let range = NSRange(location: requestCurrentOffset, length: respondLength)
        if let responseData = cacheManager.cachedData(in: range) {
            dataRequest.respond(with: responseData)
            print(
                "Responded \(respondLength.formatted(.number)) bytes from offset \(requestCurrentOffset.formatted(.number)) (remaining req: \(requestUnreadLength.formatted(.number)), cached: \(cachedUnreadLength.formatted(.number)))"
            )
        } else {
            print("Failed to get cached data for range \(range)")
            return false
        }

        // Return true only if this chunk completed the full request
        let isFull = (requestCurrentOffset + respondLength >= requestEndOffset)
        print(
            "Data request \(isFull ? "FULLY" : "PARTIALLY") handled (now at \((requestCurrentOffset + respondLength).formatted(.number))/\(requestEndOffset.formatted(.number)))"
        )
        return isFull
    }
}
