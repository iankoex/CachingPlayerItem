//
//  SwiftUIView.swift
//
//
//  Created by Ian on 13/10/2023.
//

import MediaPlayer

//extension AudioVisualService {
//    internal func setNowPlayingMetadata() {
        //        guard let itemURL = URL(string: self.item.itemURL) else {
        //            return
        //        }
        //        DispatchQueue(label: "com.iankoex.audioVisualService.nowPlayable", qos: .userInitiated).async {
        //            let metadata = NowPlayableStaticMetadata(
        //                assetURL: itemURL,
        //                mediaType: self.item.type == .audio ? .audio : .video,
        //                isLiveStream: false,
        //                title: "First Song",
        //                artist: self.item.creator.displayName,
        //                artwork: self.artwork(from: self.item.previewPicture.originalQualityURL),
        //                albumArtist: self.item.creator.displayName,
        //                albumTitle: self.item.community.name
        //            )
        ////
        ////            self.nowPlayableBehavior.handleNowPlayableItemChange(metadata: metadata)
        //        }
//    }

    //    private func artwork(from imageURL: URL) -> MPMediaItemArtwork? {
    //        #if os(macOS)
    //        let image = UnifiedImage(named: "imageName")!
    //        #else
    //        guard let image = try? UIImage(data: Data(contentsOf: imageURL)) else {
    //            return nil
    //        }
    //        #endif
    //
    //        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    //    }
//}
