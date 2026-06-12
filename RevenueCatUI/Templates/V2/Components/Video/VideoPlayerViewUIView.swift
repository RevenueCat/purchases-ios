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
@_spi(Internal) import RevenueCat
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
        // Defense-in-depth: disabling video-frame-analysis removes one family of `currentItem.*`
        // observers that AVKit's internal AVPlayerController registers and that can crash on teardown.
        #if os(iOS)
        if #available(iOS 16.0, *) {
            controller.allowsVideoFrameAnalysis = false
        }
        #endif

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

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        // Deterministically tear the player down before the controller deallocates.
        uiViewController.player?.pause()
        uiViewController.player = nil
        coordinator.tearDown()
    }

    class Coordinator {

        let player: AVPlayer

        private var previousCategory: AVAudioSession.Category?
        private var previousMode: AVAudioSession.Mode?
        private var previousOptions: AVAudioSession.CategoryOptions?

        private let autoplayHandler: VideoAutoplayHandler
        private var loopObserver: NSObjectProtocol?

        init(
            videoURL: URL,
            shouldAutoPlay: Bool,
            loopVideo: Bool,
            muteAudio: Bool
        ) {
            let playerItem = AVPlayerItem(url: videoURL)
            let avPlayer = AVPlayer(playerItem: playerItem)
            // Loop manually instead of via AVPlayerLooper/AVQueuePlayer. AVPlayerLooper swaps the
            // queue player's currentItem without sending KVO notifications, which crashes
            // AVPlayerViewController's internal observers (e.g. on `currentItem.status`) on teardown.
            avPlayer.actionAtItemEnd = loopVideo ? .none : .pause

            avPlayer.isMuted = muteAudio
            #if !os(visionOS)
            avPlayer.preventsDisplaySleepDuringVideoPlayback = false
            avPlayer.allowsExternalPlayback = false
            #endif

            self.player = avPlayer

            let audioSession = AVAudioSession.sharedInstance()
            self.previousCategory = audioSession.category
            self.previousMode = audioSession.mode
            self.previousOptions = audioSession.categoryOptions
            do {
                try audioSession.setCategory(
                    .ambient,
                    mode: .default,
                    options: [.mixWithOthers]
                )
            } catch {
                Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
            }

            self.autoplayHandler = VideoAutoplayHandler(
                playbackController: avPlayer,
                lifecycleObserver: SystemAppLifecycleObserver()
            )

            if loopVideo {
                self.loopObserver = NotificationCenter.default.addObserver(
                    forName: AVPlayerItem.didPlayToEndTimeNotification,
                    object: playerItem,
                    queue: .main
                ) { [weak avPlayer] _ in
                    avPlayer?.seek(to: .zero)
                    avPlayer?.play()
                }
            }

            if shouldAutoPlay {
                avPlayer.play()
            }
        }

        func tearDown() {
            player.pause()
            if let loopObserver = self.loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
                self.loopObserver = nil
            }
        }

        deinit {
            if let loopObserver = self.loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }

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
