//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoPlayerLayerUIView.swift
//
//  Created by RevenueCat.

import AVKit
@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - PlayerLayerBackedView

/// A `UIView` whose backing layer is an `AVPlayerLayer`.
///
/// Using an `AVPlayerLayer` directly (rather than an `AVPlayerViewController`) avoids AVKit's
/// internal `AVPlayerController`, which observes `currentItem.*` key paths on the player. When the
/// player is an `AVQueuePlayer` driven by an `AVPlayerLooper`, those observers crash on teardown
/// because the looper swaps `currentItem` without sending KVO notifications.
final class PlayerLayerBackedView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        return layer as! AVPlayerLayer
    }

}

// MARK: - VideoPlayerLayerView

/// Renders a looping/auto-playing video without playback controls via an `AVPlayerLayer`.
///
/// This is the no-controls path (used for video backgrounds). It intentionally does not use
/// `AVPlayerViewController`, so the `AVPlayerLooper`/`AVQueuePlayer` KVO crash cannot occur.
struct VideoPlayerLayerView: UIViewRepresentable {

    let videoURL: URL
    let shouldAutoPlay: Bool
    let contentMode: ContentMode
    let loopVideo: Bool
    let muteAudio: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            videoURL: videoURL,
            shouldAutoPlay: shouldAutoPlay,
            loopVideo: loopVideo,
            muteAudio: muteAudio
        )
    }

    func makeUIView(context: Context) -> PlayerLayerBackedView {
        let view = PlayerLayerBackedView()
        view.backgroundColor = .clear
        // No controls: let carousel swipes pass through (parity with the controls-hidden path).
        view.isUserInteractionEnabled = false
        view.playerLayer.player = context.coordinator.player

        switch contentMode {
        case .fit:
            view.playerLayer.videoGravity = .resizeAspect
        case .fill:
            view.playerLayer.videoGravity = .resizeAspectFill
        }

        return view
    }

    func updateUIView(_ uiView: PlayerLayerBackedView, context: Context) { }

    static func dismantleUIView(_ uiView: PlayerLayerBackedView, coordinator: Coordinator) {
        // Deterministically stop playback before the view/coordinator deallocates, so audio and
        // rendering stop promptly (e.g. on carousel navigation), mirroring the controls path.
        coordinator.tearDown()
        uiView.playerLayer.player = nil
    }

    class Coordinator {

        let player: AVPlayer

        // Retained for the lifetime of the player so looping keeps working.
        private let looper: AVPlayerLooper?
        private let autoplayHandler: VideoAutoplayHandler

        private var previousCategory: AVAudioSession.Category?
        private var previousMode: AVAudioSession.Mode?
        private var previousOptions: AVAudioSession.CategoryOptions?

        init(
            videoURL: URL,
            shouldAutoPlay: Bool,
            loopVideo: Bool,
            muteAudio: Bool
        ) {
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

            if shouldAutoPlay {
                avPlayer.play()
            }
        }

        func tearDown() {
            player.pause()
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
