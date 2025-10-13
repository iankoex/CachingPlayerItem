//
//  AudioTapProcessor.swift
//  AudioVisualService
//
//  Created by ian on 13/10/2025.
//

import AVFoundation

class AudioTapProcessor: NSObject {
    var delegate: AudioTapProcessorDelegate
    var supportedTapProcessingFormat = false
    var audioStreamBasicDescription: AudioStreamBasicDescription?
    var player: AVPlayer

    init(player: AVPlayer, audioAssetTrack: AVAssetTrack, delegate: AudioTapProcessorDelegate) {
        self.player = player
        self.delegate = delegate
        super.init()

        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()),
            init: AudioTapProcessor.tapInit,
            finalize: AudioTapProcessor.tapFinalize,
            prepare: AudioTapProcessor.tapPrepare,
            unprepare: nil,
            process: AudioTapProcessor.tapProcess
        )
        //        var audioProcessingTap: Unmanaged<MTAudioProcessingTap>?
        //        if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
        //            let audioMixInputParameters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
        //            audioMixInputParameters.audioTapProcessor = audioProcessingTap?.takeUnretainedValue()
        //            audioProcessingTap?.release()
        //            let mutableAudioMix = AVMutableAudioMix()
        //            mutableAudioMix.inputParameters = [audioMixInputParameters]
        //            player.currentItem?.audioMix = mutableAudioMix
        //        }
    }

    static let tapInit: MTAudioProcessingTapInitCallback = { (tap, clientInfo, tapStorageOut) in
        tapStorageOut.pointee = clientInfo
    }

    static let tapFinalize: MTAudioProcessingTapFinalizeCallback = { (tap) in
        Unmanaged<AudioTapProcessor>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
    }

    static let tapPrepare: MTAudioProcessingTapPrepareCallback = { (tap, itemCount, basicDescription) in
        let context = Unmanaged<AudioTapProcessor>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        context.audioStreamBasicDescription = basicDescription.pointee
        context.supportedTapProcessingFormat = true
        if basicDescription.pointee.mFormatID != kAudioFormatLinearPCM {
            context.supportedTapProcessingFormat = false
        }
        if (basicDescription.pointee.mFormatFlags & kAudioFormatFlagIsFloat) == 0 {
            context.supportedTapProcessingFormat = false
        }
    }

    static let tapProcess: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        let context = Unmanaged<AudioTapProcessor>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()

        guard context.supportedTapProcessingFormat else {
            return
        }
        guard
            MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
                == noErr
        else {
            return
        }

        context.processAudioData(audioData: bufferListInOut, framesNumber: UInt32(numberFrames))
    }

    func processAudioData(audioData: UnsafeMutablePointer<AudioBufferList>, framesNumber: UInt32) {
        var sbuf: CMSampleBuffer?
        var format: CMFormatDescription?

        guard var audioFormat = self.audioStreamBasicDescription else {
            return
        }

        guard
            CMAudioFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                asbd: &audioFormat,
                layoutSize: 0,
                layout: nil,
                magicCookieSize: 0,
                magicCookie: nil,
                extensions: nil,
                formatDescriptionOut: &format
            ) == noErr
        else {
            return
        }

        var timing = CMSampleTimingInfo(
            duration: CMTimeMake(value: 1, timescale: Int32(audioFormat.mSampleRate)),
            presentationTimeStamp: self.player.currentTime(),
            decodeTimeStamp: CMTime.invalid
        )

        guard
            CMSampleBufferCreate(
                allocator: kCFAllocatorDefault,
                dataBuffer: nil,
                dataReady: Bool(truncating: 0),
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: format,
                sampleCount: CMItemCount(framesNumber),
                sampleTimingEntryCount: 1,
                sampleTimingArray: &timing,
                sampleSizeEntryCount: 0, sampleSizeArray: nil,
                sampleBufferOut: &sbuf
            ) == noErr
        else {
            return
        }

        guard
            CMSampleBufferSetDataBufferFromAudioBufferList(
                sbuf!,
                blockBufferAllocator: kCFAllocatorDefault,
                blockBufferMemoryAllocator: kCFAllocatorDefault,
                flags: 0,
                bufferList: audioData
            ) == noErr
        else {
            return
        }

        guard let sbuf = sbuf else {
            return
        }
        self.delegate.audioTabProcessor(didReceive: sbuf)
    }
}

protocol AudioTapProcessorDelegate {
    func audioTabProcessor(didReceive buffer: CMSampleBuffer)
}
