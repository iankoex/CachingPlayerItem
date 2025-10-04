//
//  CachingPlayerItem+URLSession.swift
//  CachingPlayerItem
//
//  Created by ian on 04/10/2025.
//

import AVKit
import Foundation

// MARK: URLSessionTaskDelegate

extension CachingPlayerItem: URLSessionTaskDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            self.invalidateURLSession()
        }  // else downloaded all the video successfully
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

    nonisolated public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        cacheManager.cacheURLResponse(response)
        self.processRequests()
        completionHandler(.allow)
    }
}
