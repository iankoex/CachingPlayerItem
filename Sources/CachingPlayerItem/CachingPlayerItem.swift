//
//  CachingPlayerItem.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import Foundation
import AVFoundation

public final class CachingPlayerItem: AVPlayerItem, Sendable {
    nonisolated private let cacheManager: VideoCacheManager
    private var urlSession: URLSession?
    private let url: URL
    private var loadingRequests: [AVAssetResourceLoadingRequest] = []
    private var currentDataTask: URLSessionDataTask?
    
    // MARK: Public init
    nonisolated public init(url: URL, identifier: String = "") {
        self.url = url
        let urlWithCustomScheme = Self.replaceScheme(of: url, with: "customcache")
        
        let asset = AVURLAsset(url: urlWithCustomScheme)
        self.cacheManager = VideoCacheManager(for: url, identifier: identifier)
        
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        asset.resourceLoader.setDelegate(self, queue: .global(qos: .userInteractive))
    }
    
    deinit {
        invalidate()
    }
    
    public func invalidate() {
        self.loadingRequests.forEach { $0.finishLoading() }
        self.invalidateURLSession()
    }
    
    private func invalidateURLSession() {
        currentDataTask?.cancel()
        currentDataTask = nil
        self.urlSession?.invalidateAndCancel()
    }
    
    nonisolated static func replaceScheme(of url: URL, with scheme: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url ?? url
    }
}

// MARK: AVAssetResourceLoaderDelegate

extension CachingPlayerItem: AVAssetResourceLoaderDelegate {
    
    /// Intercepts loading requests to serve cached data or download data as needed.
    nonisolated public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        // Try to handle the request from cache
        if handleRequestFromCacheIfPossible(loadingRequest) {
            return true
        }
        
        createURLSessionThenLoad()
        loadingRequests.append(loadingRequest)
        return true
    }
    
    nonisolated public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        if let index = self.loadingRequests.firstIndex(of: loadingRequest) {
            self.loadingRequests.remove(at: index)
        }
    }
    
}

// MARK: AVAssetResourceLoaderDelegate Methods

extension CachingPlayerItem {
    
    private func createURLSessionThenLoad() {
        guard urlSession == nil else { return }
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let operationQueue = OperationQueue()
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        createDataTaskAndLoad()
    }
    
    private func createDataTaskAndLoad() {
        var request = URLRequest(url: url)
        // This will cheat the loader to think it is loading some bytes and therefore
        // call resourceLoader with dataRequest which will then be processed from the cache
        let cachedBytes = cacheManager.isFullyCached ? cacheManager.fileSize() - 1 : cacheManager.fileSize()
        
        // Set range header to resume download from where cache ends
        request.setValue("bytes=\(cachedBytes)-", forHTTPHeaderField: "Range")
        currentDataTask = urlSession?.dataTask(with: request)
        currentDataTask?.resume()
    }
    
    nonisolated private func handleRequestFromCacheIfPossible(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        // If the request is for content info, handle from cache if possible
        var request = loadingRequest
        if isContentInformationRequest(request), let cachedResponse = cacheManager.getCachedResponse() {
            fillContentInformationRequest(for: &request, using: cachedResponse)
            return false
        }
        
        // Check if the data request can be fully served from cache
        guard let dataRequest = request.dataRequest else { return false }
        guard cachedDataIsEnoughToFullfilRequest(dataRequest) else { return false }
        request.finishLoading()
        return true
    }
    
    nonisolated private func cachedDataIsEnoughToFullfilRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let cachedBytes = cacheManager.fileSize()
        guard requestedLength > 2 else { return false }
        
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
    
    nonisolated private func processRequests() {
        var finishedRequests = Set<AVAssetResourceLoadingRequest>()
        
        for var request in loadingRequests {
            // Fill information from cache if available
            if isContentInformationRequest(request), let response = cacheManager.getCachedResponse() {
                fillContentInformationRequest(for: &request, using: response)
            }
            
            // Respond to data requests with cached data
            if let dataRequest = request.dataRequest, checkAndRespond(forRequest: dataRequest) {
                finishedRequests.insert(request)
                request.finishLoading()
            }
        }
        
        // Remove finished requests
        loadingRequests = loadingRequests.filter { !finishedRequests.contains($0) }
    }
    
    nonisolated private func isContentInformationRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        return request.contentInformationRequest != nil
    }
    
    nonisolated private func fillContentInformationRequest(for request: inout AVAssetResourceLoadingRequest, using response: URLResponse) {
        request.contentInformationRequest?.isByteRangeAccessSupported = true
        request.contentInformationRequest?.contentType = response.mimeType
        request.contentInformationRequest?.contentLength = response.expectedContentLength
    }
    
    nonisolated private func checkAndRespond(forRequest dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let downloadedDataLength = cacheManager.fileSize()
        
        let requestRequestedOffset = Int(dataRequest.requestedOffset)
        let requestRequestedLength = Int(dataRequest.requestedLength)
        let requestCurrentOffset = Int(dataRequest.currentOffset)
        
        if downloadedDataLength < requestCurrentOffset {
            return false
        }
        
        let downloadedUnreadDataLength = downloadedDataLength - requestCurrentOffset
        let requestUnreadDataLength = requestRequestedOffset + requestRequestedLength - requestCurrentOffset
        let respondDataLength = min(requestUnreadDataLength, downloadedUnreadDataLength)
        let range = NSRange(location: requestCurrentOffset, length: respondDataLength)
        if let responseData = cacheManager.cachedData(in: range) {
            dataRequest.respond(with: responseData)
        }
        
        let requestEndOffset = requestRequestedOffset + requestRequestedLength
        
        return requestCurrentOffset >= requestEndOffset
    }
}

// MARK: URLSessionTaskDelegate

extension CachingPlayerItem: URLSessionTaskDelegate {
    nonisolated public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            self.invalidateURLSession()
        } // else downloaded all the video successfully
    }
}

// MARK: URLSessionDataDelegate

extension CachingPlayerItem: URLSessionDataDelegate {
    
    nonisolated public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Dont append data if the video is already fully cached
        // This fixes a bug where a byte was added to the end of the file even though the video was fully cached
        // thereby corrupting the video file and making it unplayable
        if cacheManager.isFullyCached == false {
            cacheManager.appendData(data)
        }
        
        processRequests()
    }
    
    nonisolated public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        cacheManager.cacheURLResponse(response)
        self.processRequests()
        completionHandler(.allow)
    }
}
