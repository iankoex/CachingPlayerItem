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
    public var time: CMTime = .zero
    public var duration: CMTime = .zero

    private let url: String
    private var lastPlayingState: Bool? = nil
    private var timeObserver: Any?

    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.AudioVisualService.operationQueue"
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        queue.qualityOfService = .background
        return queue
    }()

    private let dispatchQueue: DispatchQueue = DispatchQueue(
        label: "com.AudioVisualService.dispatchQueue",
        qos: .background,
        attributes: .concurrent
    )

    public var isPlaying: Bool = true {
        didSet {
            isPlaying ? play() : pause()
        }
    }

    public init(_ url: String) {
        self.url = url
        initialisePlayer()
    }

    deinit {
        if let player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    private func play() {
        initialisePlayer()
        player?.play()
    }

    private func pause() {
        player?.pause()
    }

    private func initialisePlayer() {
        guard player == nil else { return }
        guard let url = URL(string: url) else { return }

        let player = createAVPlayer(using: url)

        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: player.currentItem,
            queue: operationQueue
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: dispatchQueue) { [weak self] time in
            guard self?.player?.currentItem != nil else {
                return
            }
            self?.time = time
            if self?.duration == .zero, let playerDuration = self?.player?.currentItem?.duration {
                self?.duration = playerDuration
            }
        }

        self.player = player
    }

    private func createAVPlayer(using url: URL) -> AVPlayer {
        let playerItem = CachingPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.automaticallyWaitsToMinimizeStalling = true
        return player
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

    public func seek(to timeInSeconds: Double) {
        player?.pause()
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .positiveInfinity, toleranceAfter: .positiveInfinity)
    }
}
