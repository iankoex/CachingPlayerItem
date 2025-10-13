//
//  ResourceLoader+AVAssetResourceLoaderDelegate.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate

@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
extension ResourceLoader: AVAssetResourceLoaderDelegate {

    /// Intercepts resource loading requests to serve cached data or initiate downloads.
    ///
    /// This method is called by AVFoundation when the asset needs to load data.
    /// The ResourceLoader checks if the requested data is available in the cache,
    /// and if not, initiates a download operation.
    ///
    /// - Parameters:
    ///   - resourceLoader: The resource loader making the request.
    ///   - loadingRequest: The loading request containing information about the data needed.
    /// - Returns: Always returns `true` to indicate asynchronous handling of the request.
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

    /// Handles cancellation of a resource loading request.
    ///
    /// This method is called when AVFoundation no longer needs the data from
    /// a previously requested loading operation. The ResourceLoader cancels
    /// any ongoing download tasks and removes the request from its queue.
    ///
    /// - Parameters:
    ///   - resourceLoader: The resource loader that cancelled the request.
    ///   - loadingRequest: The loading request that was cancelled.
    nonisolated public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        Task {
            await self.removeRequest(loadingRequest)
        }
    }

}
