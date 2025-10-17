//
//  CachingPlayerItem.swift
//  AudioVisualService
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

/// An AVPlayerItem subclass that automatically caches video content during playback.
///
/// `CachingPlayerItem` provides a convenient way to create player items that
/// cache video data as it's streamed. This improves playback performance for
/// subsequent views and enables offline playback capabilities.
///
/// The player item uses a `CachingAVURLAsset` internally to handle the caching logic.
///
/// ## Usage
///
/// ```swift
/// let playerItem = CachingPlayerItem(url: videoURL)
/// let player = AVPlayer(playerItem: playerItem)
/// player.play()
/// ```
///
/// - Note: This class is thread-safe and can be used across actor boundaries.
@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
public final class CachingPlayerItem: AVPlayerItem, Sendable {

    /// Creates a new caching player item with the specified video URL.
    ///
    /// This initializer creates a player item that will automatically cache
    /// video content during playback. The caching happens transparently in
    /// the background as the video is streamed.
    ///
    /// - Parameters:
    ///   - url: The URL of the video content to play and cache.
    ///   - automaticallyLoadedAssetKeys: Optional array of asset keys to load automatically.
    ///   - serviceDelegate: An optional delegate to receive caching and loading events.
    public init(
        url: URL,
        automaticallyLoadedAssetKeys: [String]? = ["duration", "isPlayable"],
        serviceDelegate: AudioVisualServiceDelegate? = nil
    ) {
        let asset = CachingAVURLAsset(url: url, serviceDelegate: serviceDelegate)
        super.init(asset: asset, automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
    }
}
