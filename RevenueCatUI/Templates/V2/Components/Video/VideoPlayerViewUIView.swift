//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoPlayerViewUIView.swift
//
//  Created by Jacob Zivan Rakidzich on 8/18/25.

import AVKit
import SwiftUI

#if canImport(UIKit)
import UIKit

class VideoPlayerViewUIView: UIView {
    var playerLayer: AVPlayerLayer?
    var looper: AVPlayerLooper?
    var player: AVPlayer

    required  init(
        url: URL,
        shouldAutoPlay: Bool,
        contentMode: SwiftUI.ContentMode,
        loopVideo: Bool,
        muteAudio: Bool
    ) {
        let playerItem = AVPlayerItem(url: url)

        let avPlayer: AVPlayer
        if loopVideo {
            let aVQueuePlayer = AVQueuePlayer()
            looper = AVPlayerLooper(player: aVQueuePlayer, templateItem: playerItem)
            avPlayer = aVQueuePlayer
        } else {
            avPlayer = AVPlayer(playerItem: playerItem)
            avPlayer.actionAtItemEnd = .pause
        }

        self.player = avPlayer

        super.init(frame: .zero)

        self.playerLayer = AVPlayerLayer(player: avPlayer)

        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }

        avPlayer.isMuted = muteAudio

        playerLayer?.videoGravity = switch contentMode {
        case .fit:
            .resizeAspect
        case .fill:
            .resizeAspectFill
        }

        if shouldAutoPlay {
            avPlayer.play()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

struct VideoPlayerUIView: UIViewRepresentable {
    let videoURL: URL
    let shouldAutoPlay: Bool
    let contentMode: ContentMode
    let loopVideo: Bool
    let muteAudio: Bool

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> VideoPlayerViewUIView {
        VideoPlayerViewUIView(
            url: videoURL,
            shouldAutoPlay: shouldAutoPlay && !reduceMotion,
            contentMode: contentMode,
            loopVideo: loopVideo,
            muteAudio: muteAudio
        )
    }

    func updateUIView(_ uiView: VideoPlayerViewUIView, context: Context) {
    }
}

#endif
