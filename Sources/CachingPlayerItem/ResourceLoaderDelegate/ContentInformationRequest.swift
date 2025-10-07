//
//  ResourceLoader+ContentInformationRequest.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate ContentInformationRequestMethods

extension ResourceLoader {

    /// Handles content information request. Returns true only if fully handled (with response available).
    /// Queues if no response yet (will retry after didReceive response).
    internal func handleContentInformationRequest(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        contentInformationRequest: AVAssetResourceLoadingContentInformationRequest
    ) -> Bool {
        print("handling ContentInformationRequest")

        if let response = cacheManager.getCachedResponse() {
            self.handleResponseForContentInformationRequest(
                loadingRequest: loadingRequest,
                contentInformationRequest: contentInformationRequest,
                urlResponse: response
            )
            loadingRequest.finishLoading()
            return true
        }
        print("No cached response yet for ContentInformationRequest - queuing for retry")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"

        let task = urlSession.dataTask(with: urlRequest) { _, urlResponse, error in
            guard let urlResponse, error == nil else {
                print(error)
                loadingRequest.finishLoading(with: error)
                return
            }
            self.cacheManager.cacheURLResponse(urlResponse)
            self.handleResponseForContentInformationRequest(
                loadingRequest: loadingRequest,
                contentInformationRequest: contentInformationRequest,
                urlResponse: urlResponse
            )
        }
        task.resume()
        return false
    }

    func handleResponseForContentInformationRequest(
        loadingRequest: AVAssetResourceLoadingRequest,
        contentInformationRequest: AVAssetResourceLoadingContentInformationRequest,
        urlResponse: URLResponse
    ) {
        print("ContentInformationRequest with response ok")

        contentInformationRequest.isByteRangeAccessSupported = true
        contentInformationRequest.contentType = urlResponse.mimeType
        contentInformationRequest.contentLength = urlResponse.expectedContentLength
        loadingRequest.finishLoading()
    }
}
