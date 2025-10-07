//
//  CachingAVURLAsset.swift
//  CachingPlayerItem
//
//  Created by ian on 07/10/2025.
//

import AVFoundation
import Foundation

public final class CachingAVURLAsset: AVURLAsset, @unchecked Sendable {
    let customResourceLoader: ResourceLoader

    override public init(url: URL, options: [String: Any]? = nil) {
        let urlWithCustomScheme = Self.replaceScheme(of: url, with: "customcache")
        self.customResourceLoader = ResourceLoader(url: url)
        super.init(url: urlWithCustomScheme, options: options)
        self.resourceLoader.setDelegate(self.customResourceLoader, queue: .global(qos: .userInteractive))
    }

    static func replaceScheme(of url: URL, with scheme: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url ?? url
    }
}
