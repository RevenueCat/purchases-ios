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
import RevenueCat
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - AVPlayer + VideoPlaybackController

extension AVPlayer: VideoPlaybackController {

    var isPlaying: Bool {
        return timeControlStatus == .playing
    }

}

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
        #if !os(visionOS)
        avPlayer.preventsDisplaySleepDuringVideoPlayback = false
        avPlayer.allowsExternalPlayback = false
        #endif

        self.player = avPlayer

        if shouldAutoPlay {
            avPlayer.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let audioSession = AVAudioSession.sharedInstance()
        context.coordinator.previousCategory = audioSession.category
        context.coordinator.previousMode = audioSession.mode
        context.coordinator.previousOptions = audioSession.categoryOptions

        do {
            try audioSession.setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
        }

        let controller = AVPlayerViewController()
        controller.player = player
        controller.view.backgroundColor = .clear
        controller.showsPlaybackControls = showControls
        // Disable user interaction when controls are hidden to allow scroll gestures to pass through
        if !showControls {
            controller.view.isUserInteractionEnabled = false
        }
        if #available(tvOS 14.0, *) {
            controller.allowsPictureInPicturePlayback = false
        }

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

    class Coordinator {

        var previousCategory: AVAudioSession.Category?
        var previousMode: AVAudioSession.Mode?
        var previousOptions: AVAudioSession.CategoryOptions?

        private let autoplayHandler: VideoAutoplayHandler

        init(player: AVPlayer) {
            self.autoplayHandler = VideoAutoplayHandler(
                playbackController: player,
                lifecycleObserver: SystemAppLifecycleObserver()
            )
        }

        deinit {

            guard let category = previousCategory,
                  let mode = previousMode,
                  let options = previousOptions else {
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(
                    category,
                    mode: mode,
                    options: options
                )
            } catch {
                Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
            }
        }

    }
}
#endif
