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
import Combine
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

struct VideoPlayerUIView: UIViewControllerRepresentable {
    let videoURL: URL
    let contentMode: ContentMode
    let showControls: Bool
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

        self.player = avPlayer

        if shouldAutoPlay {
            avPlayer.play()
        }
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.view.backgroundColor = .clear
        controller.showsPlaybackControls = showControls
        DispatchQueue.main.async {
            switch contentMode {
            case .fit:
                controller.videoGravity = .resizeAspect
            case .fill:
                controller.videoGravity = .resizeAspectFill
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }

    class Coordinator {
        let player: AVPlayer
        private var wasPlayingBeforeBackground: Bool = false
        private var cancellables = Set<AnyCancellable>()

        init(player: AVPlayer) {
            self.player = player

            NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
                .sink { [weak self] _ in self?.appWillResignActive() }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .sink { [weak self] _ in self?.appDidBecomeActive() }
                .store(in: &cancellables)
        }

        private func appWillResignActive() {
            wasPlayingBeforeBackground = player.timeControlStatus == .playing
        }

        private func appDidBecomeActive() {
            if wasPlayingBeforeBackground {
                player.play()
            }
        }
    }
}
#endif
