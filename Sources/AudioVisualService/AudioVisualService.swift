//
//  AudioVisualService.swift
//  AudioVisualService
//
//  Created by ian on 13/10/2025.
//

import AVFoundation
import Observation
import SwiftUI

@available(macOS 14, iOS 17, tvOS 15, watchOS 8, *)
@Observable
public final class AudioVisualService: Sendable {
    public var player: AVPlayer?
    public let url: String
    public var time: CMTime = .zero
    private var cachingPlayerItem: CachingPlayerItem?
    private var lastPlayingState: Bool? = nil
    private var timeObserver: Any?
    private let operationQueue: OperationQueue = OperationQueue()
    private let dispatchQueue: DispatchQueue = .global(qos: .background)

    public var isPlaying: Bool = true {
        didSet {
            isPlaying ? play() : pause()
        }
    }

    public init(_ url: String) {
        self.url = url
    }

    deinit {
        if let player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    private func resetCachingPlayerItem() {
        //        (cachingPlayerItem?.asset as? CachingAVURLAsset)?.customResourceLoader.invalidate()
        cachingPlayerItem = nil
    }

    private func play() {
        configurePlayer()
        player?.play()
    }

    private func pause() {
        player?.pause()
        resetCachingPlayerItem()
    }

    private func configurePlayer() {
        if cachingPlayerItem == nil {
            setCurrentPlayerItem()
        } else {
            initialisePlayer()
        }
    }

    private func initialisePlayer() {
        guard player == nil else { return }
        guard let url = URL(string: url) else { return }

        let player = createAVPlayer(using: url)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: operationQueue
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: dispatchQueue
        ) { [weak self] time in
            guard self?.player?.currentItem != nil else {
                return
            }
            self?.time = time
        }

        self.player = player
    }

    private func setCurrentPlayerItem() {
        guard player != nil else {
            initialisePlayer()
            return
        }
        guard let url = URL(string: url) else { return }

        let newPlayer = createAVPlayer(using: url)
        let _ = newPlayer.publisher(for: \.timeControlStatus).sink { [weak self] timeControlStatus in
            if timeControlStatus == .playing {
                self?.player = newPlayer
                self?.player?.play()
            }
        }
    }

    private func createAVPlayer(using url: URL) -> AVPlayer {
        let playerItem = getCachingPlayerItem(using: url)
        let player = AVPlayer(playerItem: playerItem)
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.play()
        return player
    }

    private func getCachingPlayerItem(using url: URL) -> CachingPlayerItem {
        if let cachingPlayerItem {
            return cachingPlayerItem
        }
        cachingPlayerItem = CachingPlayerItem(url: url)
        cachingPlayerItem?.preferredForwardBufferDuration = TimeInterval(1)
        return getCachingPlayerItem(using: url)
    }

    public func setLastPlayingState() {
        if lastPlayingState == nil {
            lastPlayingState = isPlaying
        }
        isPlaying = false
    }

    public func restoreLastPlayingState() {
        isPlaying = lastPlayingState ?? false
        lastPlayingState = nil
    }
}
