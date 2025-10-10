//
//  ResourceLoader+LoadingRequest.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

// MARK: AVAssetResourceLoaderDelegate Methods

extension ResourceLoader {
    internal func addRequest(_ request: AVAssetResourceLoadingRequest) {
        loadingRequests.append(request)
        processRequests()
    }

    func removeRequest(_ request: AVAssetResourceLoadingRequest) {
        if let index = loadingRequests.firstIndex(of: request) {
            pendingRequests[loadingRequests[index]]?.cancel()
            loadingRequests.remove(at: index)
        }
    }

    func processRequests() {
        loadingRequests.removeAll { request in
            let isHandled = handleLoadingRequest(request)
            return isHandled
        }
    }

    internal func handleLoadingRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        if let contentInformationRequest = request.contentInformationRequest {
            return handleContentInformationRequest(request, contentInformationRequest: contentInformationRequest)
        } else if let dataRequest = request.dataRequest {
            return handleDataRequest(request, dataRequest: dataRequest)
        }
        return false
    }
}
