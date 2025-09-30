//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoPlayerViewNSView.swift
//
//  Created by Jacob Zivan Rakidzich on 8/18/25.

import AVKit
import SwiftUI

#if os(macOS)
import AppKit

class VideoPlayerViewNSView: NSView {
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    var looper: AVPlayerLooper?

    required init(
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
            layer = playerLayer
        }

        avPlayer.isMuted = muteAudio

        switch contentMode {
        case .fit:
            playerLayer?.videoGravity = .resizeAspect
        case .fill:
            playerLayer?.videoGravity = .resizeAspectFill
        }

        if shouldAutoPlay {
            avPlayer.play()
        }

        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}

struct VideoPlayerNSView: NSViewRepresentable {
    let videoURL: URL
    let shouldAutoPlay: Bool
    let contentMode: SwiftUI.ContentMode
    let loopVideo: Bool
    let muteAudio: Bool

    func makeNSView(context: Context) -> VideoPlayerViewNSView {
        let view = VideoPlayerViewNSView(
            url: videoURL,
            shouldAutoPlay: shouldAutoPlay,
            contentMode: contentMode,
            loopVideo: loopVideo,
            muteAudio: muteAudio
        )

        return view
    }

    func updateNSView(_ nsView: VideoPlayerViewNSView, context: Context) { }
}

#endif
