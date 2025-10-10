//
//  ResourceLoader+AVAssetResourceLoaderDelegate.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate

extension ResourceLoader: AVAssetResourceLoaderDelegate {

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
