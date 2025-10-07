//
//  CachingPlayerItem.swift
//  CachingPlayerItem
//
//  Created by ian on 10/31/24.
//

import AVFoundation
import Foundation

public final class CachingPlayerItem: AVPlayerItem, Sendable {

    public init(url: URL, automaticallyLoadedAssetKeys: [String]? = nil) {
        let asset = CachingAVURLAsset(url: url)

        super.init(asset: asset, automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
    }
}
