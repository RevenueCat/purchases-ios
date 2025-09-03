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
            let player: AVPlayer
            let loop: Bool

            init(url: URL, shouldAutoPlay: Bool, loopVideo: Bool, muteAudio: Bool) {
                let item = AVPlayerItem(url: url)
                self.player = AVPlayer(playerItem: item)
                player.isMuted = muteAudio
                loop = loopVideo
                if shouldAutoPlay {
                    player.play()
                }
            }

            var body: some View {
                VideoPlayer(player: player)
                    .onReceive(
                        NotificationCenter.default
                            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification)
                            .receive(on: RunLoop.main)
                    ) { _ in
                        if loop {
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            }
        }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview("No controls, no loop") {
    VStack {
        VideoPlayerView(
            videoURL: .init(string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4")!,
            shouldAutoPlay: true,
            contentMode: .fit,
            showControls: false,
            loopVideo: false,
            muteAudio: true
        )
    }.background(Color.accentColor)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview("No controls, w/ loop") {
    VStack {
        VideoPlayerView(
            videoURL: .init(string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4")!,
            shouldAutoPlay: true,
            contentMode: .fit,
            showControls: false,
            loopVideo: true,
            muteAudio: true
        )
    }.background(Color.accentColor)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview("Controls, no loop") {
    VStack {
        VideoPlayerView(
            videoURL: .init(string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4")!,
            shouldAutoPlay: true,
            contentMode: .fit,
            showControls: true,
            loopVideo: false,
            muteAudio: true
        )
        .padding()
    }.background(Color.accentColor)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview("Loop, w/ controls") {
    VStack {
        VideoPlayerView(
            videoURL: .init(string: "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4")!,
            shouldAutoPlay: true,
            contentMode: .fit,
            showControls: true,
            loopVideo: true,
            muteAudio: true
        )
        .padding()
    }.background(Color.accentColor)
}
