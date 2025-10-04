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
        createURLSessionThenLoad()
        loadingRequests.append(loadingRequest)
        return handleLoadingRequest(loadingRequest)
    }

    nonisolated public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        if let index = self.loadingRequests.firstIndex(of: loadingRequest) {
            self.loadingRequests.remove(at: index)
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

    //    nonisolated private func handleRequestFromCacheIfPossible(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    //        // If the request is for content info, handle from cache if possible
    //        var request = loadingRequest
    //
    //        print("isContentInformationRequest 1", request.contentInformationRequest != nil)
    //
    //        if isContentInformationRequest(request), let cachedResponse = cacheManager.getCachedResponse() {
    //            fillContentInformationRequest(for: &request, using: cachedResponse)
    //            return true
    //        }
    //
    //        // Check if the data request can be fully served from cache
    //        guard let dataRequest = request.dataRequest else { return false }
    //        guard cachedDataIsEnoughToFullfilRequest(dataRequest) else { return false }
    //        request.finishLoading()
    //        return true
    //    }

    //    nonisolated private func cachedDataIsEnoughToFullfilRequest(
    //        _ dataRequest: AVAssetResourceLoadingDataRequest
    //    ) -> Bool {
    //        let requestedOffset = Int(dataRequest.requestedOffset)
    //        let requestedLength = dataRequest.requestedLength
    //        let cachedBytes = cacheManager.fileSize()
    //        guard requestedLength > 2 else { return false }
    //
    //        // Serve the range directly if fully cached
    //        if cachedBytes >= requestedOffset + requestedLength {
    //            let range = NSRange(location: requestedOffset, length: requestedLength)
    //            if let cachedData = cacheManager.cachedData(in: range) {
    //                dataRequest.respond(with: cachedData)
    //                return true
    //            }
    //        } else if cachedBytes > requestedOffset {
    //            // Partially cached: Serve what we can
    //            let availableLength = cachedBytes - requestedOffset
    //            let range = NSRange(location: requestedOffset, length: availableLength)
    //            if let cachedData = cacheManager.cachedData(in: range) {
    //                dataRequest.respond(with: cachedData)
    //                return true
    //            }
    //        }
    //        return false
    //    }

    nonisolated internal func processRequests() {
        var finishedRequests = Set<AVAssetResourceLoadingRequest>()

        for var request in loadingRequests {
            print("isContentInformationRequest", request.contentInformationRequest != nil)

            if handleLoadingRequest(request) {
                finishedRequests.insert(request)
            }
        }

        // Remove finished requests
        loadingRequests = loadingRequests.filter { !finishedRequests.contains($0) }
    }

    nonisolated internal func handleLoadingRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        if request.contentInformationRequest != nil {
            return handleContentInformationRequest(request)
        } else if let dataRequest = request.dataRequest, handleDataRequest(dataRequest) {
            request.finishLoading()
            return true
        } else {
            return false
        }
    }

    nonisolated internal func handleContentInformationRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let response = cacheManager.getCachedResponse() else {
            //            request.finishLoading(with: error)
            return false
        }
        request.contentInformationRequest?.isByteRangeAccessSupported = true
        request.contentInformationRequest?.contentType = response.mimeType
        request.contentInformationRequest?.contentLength = response.expectedContentLength
        request.finishLoading()
        return true
    }

    nonisolated private func handleDataRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        //        let downloadedDataLength = cacheManager.fileSize()
        //
        //        let requestRequestedOffset = Int(dataRequest.requestedOffset)
        //        let requestRequestedLength = Int(dataRequest.requestedLength)
        //        let requestCurrentOffset = Int(dataRequest.currentOffset)
        //
        //        if downloadedDataLength < requestCurrentOffset {
        //            return false
        //        }
        //
        //        let downloadedUnreadDataLength = downloadedDataLength - requestCurrentOffset
        //        let requestUnreadDataLength = requestRequestedOffset + requestRequestedLength - requestCurrentOffset
        //        let respondDataLength = min(requestUnreadDataLength, downloadedUnreadDataLength)
        //        let range = NSRange(location: requestCurrentOffset, length: respondDataLength)
        //
        //        if let responseData = cacheManager.cachedData(in: range) {
        //            dataRequest.respond(with: responseData)
        //        }
        //
        //        let requestEndOffset = requestRequestedOffset + requestRequestedLength
        //
        //        return requestCurrentOffset >= requestEndOffset

        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        guard requestedLength > 2 else { return false }
        let cachedBytes = cacheManager.fileSize()

        print("we have cachedBytes", cachedBytes.formatted(.number), "requestedOffset", requestedOffset.formatted(.number), "requestedLength", requestedLength.formatted(.number))

        // Serve the range directly if fully cached
        if cachedBytes >= requestedOffset + requestedLength {
            let range = NSRange(location: requestedOffset, length: requestedLength)
            if let cachedData = cacheManager.cachedData(in: range) {
                dataRequest.respond(with: cachedData)
                return true
            }
        } else if cachedBytes > requestedOffset {
            // Partially cached: Serve what we can
            let availableLength = cachedBytes - requestedOffset
            let range = NSRange(location: requestedOffset, length: availableLength)
            if let cachedData = cacheManager.cachedData(in: range) {
                dataRequest.respond(with: cachedData)
                return true
            }
        }
        return false
    }
}
