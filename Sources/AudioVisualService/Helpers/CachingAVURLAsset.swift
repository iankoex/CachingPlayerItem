//
//  CachingAVURLAsset.swift
//  AudioVisualService
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

/// An AVURLAsset subclass that provides automatic caching of video content.
///
/// `CachingAVURLAsset` intercepts AVFoundation's resource loading requests to
/// cache video data locally. This enables smoother playback, offline viewing,
/// and reduced network usage for previously viewed content.
///
/// The asset uses a custom URL scheme to intercept loading requests and
/// delegates them to a `ResourceLoader` that manages caching logic.
///
/// ## Usage
///
/// ```swift
/// let asset = CachingAVURLAsset(url: videoURL)
/// let playerItem = AVPlayerItem(asset: asset)
/// let player = AVPlayer(playerItem: playerItem)
/// ```
///
/// - Note: This class is thread-safe and can be used across actor boundaries.
@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
public final class CachingAVURLAsset: AVURLAsset, @unchecked Sendable {
    let customResourceLoader: ResourceLoader
    private let resourceLoaderQueue = DispatchQueue(label: "com.AudioVisualService")

    /// Creates a new caching AVURLAsset with the specified URL.
    ///
    /// This initializer creates an asset that will automatically cache video content
    /// as it's played. The URL scheme is modified internally to enable interception
    /// of resource loading requests.
    ///
    /// - Parameters:
    ///   - url: The URL of the video content to load and cache.
    ///   - options: Optional asset loading options passed to the superclass.
    ///   - serviceDelegate: An optional delegate to receive caching and loading events.
    public init(
        url: URL,
        options: [String: Any]? = nil,
        serviceDelegate: AudioVisualServiceDelegate? = nil
    ) {
        let urlWithCustomScheme = Self.replaceScheme(of: url, with: "customcache")
        self.customResourceLoader = ResourceLoader(url: url, serviceDelegate: serviceDelegate)
        super.init(url: urlWithCustomScheme, options: options)
        self.resourceLoader.setDelegate(self.customResourceLoader, queue: resourceLoaderQueue)
    }

    /// Replaces the URL scheme of the given URL with a new scheme.
    ///
    /// This method is used internally to modify the URL scheme to enable
    /// interception of resource loading requests by the custom resource loader.
    ///
    /// - Parameters:
    ///   - url: The original URL whose scheme should be replaced.
    ///   - scheme: The new scheme to use.
    /// - Returns: A new URL with the replaced scheme, or the original URL if modification fails.
    static func replaceScheme(of url: URL, with scheme: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url ?? url
    }

    /// Explicitly tear down resource loading to avoid dangling references.
    deinit {
        // Break delegate retain path first.
        resourceLoader.setDelegate(nil, queue: nil)
    }
}
