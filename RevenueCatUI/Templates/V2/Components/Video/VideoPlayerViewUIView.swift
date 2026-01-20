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
import AVFoundation
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

struct VideoPlayerUIView: UIViewControllerRepresentable {
    let videoURL: URL
    let contentMode: ContentMode
    let showControls: Bool
    let shouldAutoPlay: Bool
    let player: AVPlayer
    let looper: AVPlayerLooper?

    init(
        videoURL: URL,
        shouldAutoPlay: Bool,
        contentMode: ContentMode,
        loopVideo: Bool,
        showControls: Bool,
        muteAudio: Bool
    ) {
        self.videoURL = videoURL
        self.contentMode = contentMode
        self.showControls = showControls
        self.shouldAutoPlay = shouldAutoPlay

        let playerItem = AVPlayerItem(url: videoURL)

        let avPlayer: AVPlayer
        if loopVideo {
            let aVQueuePlayer = AVQueuePlayer()
            self.looper = AVPlayerLooper(player: aVQueuePlayer, templateItem: playerItem)
            avPlayer = aVQueuePlayer
        } else {
            avPlayer = AVPlayer(playerItem: playerItem)
            avPlayer.actionAtItemEnd = .pause
            self.looper = nil
        }

        avPlayer.isMuted = muteAudio
        avPlayer.preventsDisplaySleepDuringVideoPlayback = false
        avPlayer.allowsExternalPlayback = false

        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            mode: .default,
            options: [.mixWithOthers]
        )

        self.player = avPlayer

        if shouldAutoPlay {
            avPlayer.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.view.backgroundColor = .clear
        controller.showsPlaybackControls = showControls

        // Prevent video from appearing in Control Center / Lock Screen
        controller.allowsPictureInPicturePlayback = false
        player.allowsExternalPlayback = false

        switch contentMode {
        case .fit:
            controller.videoGravity = .resizeAspect
        case .fill:
            controller.videoGravity = .resizeAspectFill
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { }

    class Coordinator: NSObject {
        let player: AVPlayer
        private var wasPlayingBeforeBackground = false

        init(player: AVPlayer) {
            self.player = player
            super.init()

            // Track playing state before app goes to background
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )

            // Resume playback when app becomes active (after screen unlock or returning from background)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }

        @objc private func appWillResignActive() {
            wasPlayingBeforeBackground = player.timeControlStatus == .playing
        }

        @objc private func appDidBecomeActive() {
            if wasPlayingBeforeBackground {
                player.play()
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
#endif
