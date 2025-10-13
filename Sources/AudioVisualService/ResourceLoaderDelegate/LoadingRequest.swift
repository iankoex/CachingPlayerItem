//
//  ResourceLoader+LoadingRequest.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate Methods

@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
extension ResourceLoader {
    /// Adds a new loading request to the queue and begins processing it.
    ///
    /// This method queues the request and immediately attempts to fulfill it
    /// by checking for cached data or initiating a download.
    ///
    /// - Parameter request: The loading request to add and process.
    internal func addRequest(_ request: AVAssetResourceLoadingRequest) {
        loadingRequests.append(request)
        processRequests()
    }

    /// Removes a loading request from the queue and cancels any associated downloads.
    ///
    /// This method is called when a request is cancelled or completed.
    /// It ensures that any ongoing network operations are properly cancelled.
    ///
    /// - Parameter request: The loading request to remove.
    func removeRequest(_ request: AVAssetResourceLoadingRequest) {
        if let index = loadingRequests.firstIndex(of: request) {
            pendingRequests[loadingRequests[index]]?.cancel()
            loadingRequests.remove(at: index)
        }
    }

    /// Processes all pending loading requests in the queue.
    ///
    /// This method iterates through the request queue and attempts to fulfill
    /// each request. Successfully handled requests are removed from the queue.
    func processRequests() {
        loadingRequests.removeAll { request in
            let isHandled = handleLoadingRequest(request)
            return isHandled
        }
    }

    /// Handles an individual loading request by determining its type and delegating appropriately.
    ///
    /// This method examines the request to determine if it's a content information
    /// request or a data request, then calls the appropriate handler method.
    ///
    /// - Parameter request: The loading request to handle.
    /// - Returns: `true` if the request was successfully handled, `false` otherwise.
    internal func handleLoadingRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        if let contentInformationRequest = request.contentInformationRequest {
            return handleContentInformationRequest(request, contentInformationRequest: contentInformationRequest)
        } else if let dataRequest = request.dataRequest {
            return handleDataRequest(request, dataRequest: dataRequest)
        }
        return false
    }
}
