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

    /// Handles a content information request by providing cached or fetched response data.
    ///
    /// This method first checks if response information is cached. If available,
    /// it immediately provides the cached information. Otherwise, it makes a
    /// HEAD request to fetch the necessary content metadata.
    ///
    /// - Parameters:
    ///   - loadingRequest: The loading request containing this content information request.
    ///   - contentInformationRequest: The request for content information.
    /// - Returns: `true` if the request was fulfilled immediately, `false` if handled asynchronously.
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

    /// Configures the content information request with response data and completes the request.
    ///
    /// This method populates the content information request with metadata from
    /// the URL response, including MIME type, content length, and byte range support.
    /// It then marks the loading request as complete.
    ///
    /// - Parameters:
    ///   - loadingRequest: The loading request to complete.
    ///   - contentInformationRequest: The content information request to configure.
    ///   - urlResponse: The URL response containing the metadata to provide.
    nonisolated func handleResponseForContentInformationRequest(
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
