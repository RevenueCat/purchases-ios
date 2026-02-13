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
    let shouldAutoPlay: Bool
    let contentMode: ContentMode
    let loopVideo: Bool
    let showControls: Bool
    let muteAudio: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            videoURL: videoURL,
            shouldAutoPlay: shouldAutoPlay,
            loopVideo: loopVideo,
            muteAudio: muteAudio
        )
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
        controller.player = context.coordinator.player
        controller.view.backgroundColor = .clear
        controller.showsPlaybackControls = showControls
        // When controls are hidden, disable user interaction to allow carousel swipes to pass through.
        // When controls are shown, user interaction remains enabled so users can tap to play/pause,
        // seek, etc. In this case, carousel swipes over the video area won't work, which is the
        // expected behavior since the user is interacting with the video controls.
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

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Don't swap video URL during playback to avoid visual glitches.
        // Unlike Android which swaps the video source and preserves playback position,
        // iOS AVPlayer causes visible stuttering when replacing items mid-playback.
        // The high-res version will be used on next paywall open once cached.
    }

    class Coordinator {

        let player: AVPlayer
        private(set) var looper: AVPlayerLooper?

        var previousCategory: AVAudioSession.Category?
        var previousMode: AVAudioSession.Mode?
        var previousOptions: AVAudioSession.CategoryOptions?

        private let autoplayHandler: VideoAutoplayHandler

        init(
            videoURL: URL,
            shouldAutoPlay: Bool,
            loopVideo: Bool,
            muteAudio: Bool
        ) {
            let playerItem = AVPlayerItem(url: videoURL)

            let avPlayer: AVPlayer
            if loopVideo {
                let queuePlayer = AVQueuePlayer()
                self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
                avPlayer = queuePlayer
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

            self.autoplayHandler = VideoAutoplayHandler(
                playbackController: avPlayer,
                lifecycleObserver: SystemAppLifecycleObserver()
            )

            if shouldAutoPlay {
                avPlayer.play()
            }
        }

        deinit {
            // Clean up player to prevent retain cycles
            player.pause()
            player.replaceCurrentItem(with: nil)
            looper?.disableLooping()

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
