//
//  AudioVisualServiceDelegate.swift
//  AudioVisualService
//
//  Created by ian on 11/10/2025.
//

import Foundation

public protocol AudioVisualServiceDelegate: Sendable {
    /// Called when data is cached for a video asset.
    ///
    /// - Parameters:
    ///   - url: The URL of the video asset.
    ///   - totalBytesCached: The total number of bytes that have been cached.
    func didCacheData(url: URL, totalBytesCached: Int)
}
