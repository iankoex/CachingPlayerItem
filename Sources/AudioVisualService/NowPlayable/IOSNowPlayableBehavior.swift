///*
// See the LICENSE.txt file for this sample’s licensing information.
// 
// Abstract:
// `IOSNowPlayableBehavior` implements the `NowPlayable` protocol for the iOS platform.
// */
//
//import Foundation
//import MediaPlayer
//
//public class IOSNowPlayableBehavior: NowPlayable {
//    
//    public var defaultAllowsExternalPlayback: Bool { return true }
//    
//    public var defaultRegisteredCommands: [NowPlayableCommand] {
//        return [
//            .togglePausePlay,
//            .play,
//            .pause,
//            .nextTrack,
//            .previousTrack,
//            .skipBackward,
//            .skipForward,
//            .changePlaybackPosition,
//            .changePlaybackRate,
//            .enableLanguageOption,
//            .disableLanguageOption
//        ]
//    }
//    
//    public var defaultDisabledCommands: [NowPlayableCommand] {
//        
//        // By default, no commands are disabled.
//        
//        return []
//    }
//    
//    // The observer of audio session interruption notifications.
//    
//    private var interruptionObserver: NSObjectProtocol!
//    
//    // The handler to be invoked when an interruption begins or ends.
//    
//    private var interruptionHandler: (NowPlayableInterruption) -> Void = { _ in }
//    
//    public func handleNowPlayableConfiguration(
//        commands: [NowPlayableCommand],
//        disabledCommands: [NowPlayableCommand],
//        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
//        interruptionHandler: @escaping (NowPlayableInterruption) -> Void
//    ) throws {
//        
//        // Remember the interruption handler.
//        
//        self.interruptionHandler = interruptionHandler
//        
//        // Use the default behavior for registering commands.
//        
//        try configureRemoteCommands(commands, disabledCommands: disabledCommands, commandHandler: commandHandler)
//    }
//    
//    public func handleNowPlayableSessionStart() {
//        
//        let audioSession = AVAudioSession.sharedInstance()
//        
//        // Observe interruptions to the audio session.
//        
//        interruptionObserver = NotificationCenter.default.addObserver(
//            forName: AVAudioSession.interruptionNotification,
//            object: audioSession,
//            queue: .main
//        ) { [unowned self] notification in
//            self.handleAudioSessionInterruption(notification: notification)
//        }
//        
//        do {
////            try audioSession.setCategory(.playback, mode: .default)
//            try audioSession.setActive(true)
//        } catch {
//            print("Failed to activate audio session, error: \(error)")
//        }
//    }
//    
//    public func handleNowPlayableSessionEnd() {
//        
//        // Stop observing interruptions to the audio session.
//        
//        interruptionObserver = nil
//        
//        // Make the audio session inactive.
//        
//        do {
//            try AVAudioSession.sharedInstance().setActive(false)
//        } catch {
//            print("Failed to deactivate audio session, error: \(error)")
//        }
//    }
//    
//    public func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
//        
//        // Use the default behavior for setting player item metadata.
//        
//        setNowPlayingMetadata(metadata)
//    }
//    
//    public func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
//        
//        // Use the default behavior for setting playback information.
//        
//        setNowPlayingPlaybackInfo(metadata)
//    }
//    
//    // Helper method to handle an audio session interruption notification.
//    
//    private func handleAudioSessionInterruption(notification: Notification) {
//        
//        // Retrieve the interruption type from the notification.
//        
//        guard let userInfo = notification.userInfo,
//              let interruptionTypeUInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
//              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeUInt) else { return }
//        
//        // Begin or end an interruption.
//        
//        switch interruptionType {
//                
//            case .began:
//                
//                // When an interruption begins, just invoke the handler.
//                
//                interruptionHandler(.began)
//                
//            case .ended:
//                
//                // When an interruption ends, determine whether playback should resume
//                // automatically, and reactivate the audio session if necessary.
//                
//                do {
//                    
//                    try AVAudioSession.sharedInstance().setActive(true)
//                    
//                    var shouldResume = false
//                    
//                    if let optionsUInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
//                       AVAudioSession.InterruptionOptions(rawValue: optionsUInt).contains(.shouldResume) {
//                        shouldResume = true
//                    }
//                    
//                    interruptionHandler(.ended(shouldResume))
//                }
//                
//                // When the audio session cannot be resumed after an interruption,
//                // invoke the handler with error information.
//                
//                catch {
//                    interruptionHandler(.failed(error))
//                }
//                
//            @unknown default:
//                break
//        }
//    }
//    
//}
//
