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

    internal func handleContentInformationRequest(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        contentInformationRequest: AVAssetResourceLoadingContentInformationRequest
    ) -> Bool {
        if let response = cacheManager.getCachedResponse() {
            self.handleResponseForContentInformationRequest(
                loadingRequest: loadingRequest,
                contentInformationRequest: contentInformationRequest,
                urlResponse: response.urlResponse
            )
            loadingRequest.finishLoading()
            return true
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"

        let task = urlSession.dataTask(with: urlRequest) { _, urlResponse, error in
            guard let urlResponse, error == nil else {
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
        contentInformationRequest.isByteRangeAccessSupported = true
        contentInformationRequest.contentType = urlResponse.mimeType
        contentInformationRequest.contentLength = urlResponse.expectedContentLength
        loadingRequest.finishLoading()
    }
}
