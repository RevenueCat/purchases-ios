//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoPlayerView.swift
//
//  Created by Jacob Zivan Rakidzich on 8/18/25.

import AVKit
import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
#if os(watchOS)
import AVFoundation
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VideoPlayerView: View {
    let videoURL: URL
    let shouldAutoPlay: Bool
    let contentMode: ContentMode
    let showControls: Bool
    let loopVideo: Bool
    let muteAudio: Bool

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
#if os(macOS)
        if showControls {
            ViewWithControls(
                url: videoURL,
                shouldAutoPlay: shouldAutoPlay && !reduceMotion,
                loopVideo: loopVideo,
                muteAudio: muteAudio
            )
        } else {

            // WIP: Need to create a macOS version of the view with controls and a clear background.
            VideoPlayerNSView(
                videoURL: videoURL,
                shouldAutoPlay: shouldAutoPlay && !reduceMotion,
                contentMode: contentMode,
                loopVideo: loopVideo,
                muteAudio: muteAudio
            )
        }
#elseif os(watchOS)
        // Hiding controls on watchOS is not officially supported by Apple,
        // disabling hit testing will prevent the user from being able to get them to show.
        // Additionally, setting the action at end to .none will prevent them from displaying before looping.
        ViewWithControls(
            url: videoURL,
            shouldAutoPlay: shouldAutoPlay && !reduceMotion,
            loopVideo: loopVideo,
            muteAudio: muteAudio,
            actionAtEnd: (showControls && !loopVideo) ? .pause : .none
        )
        .allowsHitTesting(showControls)
#elseif canImport(UIKit)
        VideoPlayerUIView(
            videoURL: videoURL,
            shouldAutoPlay: shouldAutoPlay && !reduceMotion,
            contentMode: contentMode,
            loopVideo: loopVideo,
            showControls: showControls,
            muteAudio: muteAudio
        )
#endif
    }

    private struct ViewWithControls: View {
        let notificationCenter: NotificationCenter = .default
        let player: AVPlayer
        #if !os(watchOS)
        let looper: AVPlayerLooper?
        #else
        let loopVideo: Bool
        #endif

        init(
            url: URL,
            shouldAutoPlay: Bool,
            loopVideo: Bool,
            muteAudio: Bool,
            actionAtEnd: AVPlayer.ActionAtItemEnd = .pause
        ) {
            let item = AVPlayerItem(url: url)

            let avPlayer: AVPlayer
            #if !os(watchOS)
            if loopVideo {
                let aVQueuePlayer = AVQueuePlayer()
                self.looper = AVPlayerLooper(player: aVQueuePlayer, templateItem: item)
                avPlayer = aVQueuePlayer
            } else {
                avPlayer = AVPlayer(playerItem: item)
                avPlayer.actionAtItemEnd = actionAtEnd
                self.looper = nil
            }
            #else
            avPlayer = AVPlayer(playerItem: item)
            avPlayer.actionAtItemEnd = actionAtEnd
            self.loopVideo = loopVideo
            #endif

            avPlayer.isMuted = muteAudio

            self.player = avPlayer

            if shouldAutoPlay {
                player.play()
            }
        }

        var body: some View {
            VideoPlayer(player: player)
            #if os(watchOS)
                // This is less reliable than using the AVPlayerLooper.
                // Unfortunately, that is not available on watchOS
                .onReceive(notificationCenter.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)) { _ in
                    if loopVideo {
                        player.seek(to: .zero)
                        player.play()
                    }
                }
            #endif
        }
    }

}

// Removed macOS because Emerge was having issues ignoring UIKit for some reason
#if os(iOS) || os(watchOS)
@available(iOS 18.0, watchOS 8.0, *)
struct VideoViewPreviews: PreviewProvider {

    static var previews: some View {

        List {
            Section("No controls or loop") {
                VideoPlayerView(
                    videoURL: .init(
                        string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4"
                    )!,
                    shouldAutoPlay: true,
                    contentMode: .fit,
                    showControls: false,
                    loopVideo: false,
                    muteAudio: true
                ).frame(height: 400)
            }

            Section("No controls, w/ loop") {
                VideoPlayerView(
                    videoURL: .init(
                        string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4"
                    )!,
                    shouldAutoPlay: true,
                    contentMode: .fit,
                    showControls: false,
                    loopVideo: true,
                    muteAudio: true
                ).frame(height: 400)
            }

            Section("Controls, no loop") {
                VideoPlayerView(
                    videoURL: .init(
                        string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4"
                    )!,
                    shouldAutoPlay: true,
                    contentMode: .fit,
                    showControls: true,
                    loopVideo: false,
                    muteAudio: true
                ).frame(height: 400)
            }

            Section("Loop + controls") {
                VideoPlayerView(
                    videoURL: .init(
                        string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4"
                    )!,
                    shouldAutoPlay: true,
                    contentMode: .fit,
                    showControls: true,
                    loopVideo: true,
                    muteAudio: true
                ).frame(height: 400)
            }
        }
    }
}
#endif
