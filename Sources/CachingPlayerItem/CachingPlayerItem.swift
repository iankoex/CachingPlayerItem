//
//  CachingPlayerItem.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

public final class CachingPlayerItem: AVPlayerItem, Sendable {
    // we need the delegate to outlive the init
    let resourceLoader: ResourceLoader

    /// Initializes a CachingPlayerItem that caches video data from the given URL.
    /// - Parameter url: The URL of the video to play and cache.
    public init(url: URL) {
        let urlWithCustomScheme = Self.replaceScheme(of: url, with: "customcache")
        let asset = AVURLAsset(url: urlWithCustomScheme)
        self.resourceLoader = ResourceLoader(url: url)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        asset.resourceLoader.setDelegate(self.resourceLoader, queue: .global(qos: .userInteractive))
    }

    nonisolated static func replaceScheme(of url: URL, with scheme: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url ?? url
    }
}
