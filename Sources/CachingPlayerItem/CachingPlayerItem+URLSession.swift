//
//  CachingPlayerItem+URLSession.swift
//  CachingPlayerItem
//
//  Created by ian on 04/10/2025.
//

import AVKit
import Foundation

// MARK: - URLSessionTaskDelegate

extension CachingPlayerItem: URLSessionTaskDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            // Jump into the actor to safely handle completion.
            Task {
                await self.taskDidComplete(with: error)
            }
        }
    }
}

// MARK: - URLSessionDataDelegate

extension CachingPlayerItem: URLSessionDataDelegate {

    nonisolated public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        // Jump into the actor to process the response.
        Task {
            await self.handle(response: response)
        }
        completionHandler(.allow)
    }

    nonisolated public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Jump into the actor to process the incoming data.
        Task {
            await self.handle(data: data)
        }
    }
}

// MARK: - Actor-Safe URLSession Logic

extension CachingPlayerItem {

    func taskDidComplete(with error: Error?) {
        // Handle error and cleanup
        self.invalidateURLSession()
        // You might want to fail any pending requests here.
    }

    func handle(response: URLResponse) {
        cacheManager.cacheURLResponse(response)
        processRequests()
    }

    func handle(data: Data) {
        if !cacheManager.isFullyCached {
            cacheManager.appendData(data)
        }
        processRequests()
    }
}
