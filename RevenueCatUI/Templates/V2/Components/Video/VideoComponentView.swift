//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoComponentView.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/25.

import AVKit
import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VideoComponentView: View {

    private let viewModel: VideoComponentViewModel

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    init(
        viewModel: VideoComponentViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        viewModel.styles(
            state: componentViewState,
            condition: screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            )
        ) { style in
            CachingVideoPlayer(style: style)
            // T_O_D_O: Determine the best way to manage the size and aspect ratio.
            //        .applySize(size: self.style.size)
            //        .applyShape(self.style.shape)
            //        .applyColorOverlay(self.style.colorOverlay)
            //        .applyPadding(self.style.padding)
            //        .applyMargin(self.style.margin)
            //        .applyBorder(self.style.border)
            //        .applyShadow(self.style.shadow)
        }
    }
}

class VideoPlayerViewUIView: UIView {
    var playerLayer: AVPlayerLayer?
    var queuePlayer: AVQueuePlayer?
    var looper: AVPlayerLooper?

    required init(url: URL) {
        super.init(frame: .zero)

        queuePlayer = AVQueuePlayer()
        playerLayer = AVPlayerLayer(player: queuePlayer)
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }

        let playerItem = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)

        // TO DO: Figure out if we want this server driven Mute the video (common for backgrounds)
        queuePlayer?.isMuted = true

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    private func pauseVideo() {
        queuePlayer?.pause()
    }

    private func resumeVideo() {
        queuePlayer?.play()
    }

    deinit {
        looper?.disableLooping()
        looper = nil
        queuePlayer?.pause()
        queuePlayer = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    var shouldAutoPlay = true
    // to do: rename this and make it the aspect ratio type instead
    var shouldFillParent: Bool = false
    var showControls: Bool = false
    var loopVideo: Bool = false
    var muteAudio: Bool = false

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> VideoPlayerViewUIView {
        let view = VideoPlayerViewUIView(url: videoURL)

        view.playerLayer?.videoGravity = shouldFillParent ? .resizeAspectFill : .resizeAspect

        if muteAudio {
            view.queuePlayer?.isMuted = true
        }

        if shouldAutoPlay && !reduceMotion {
            view.queuePlayer?.play()
        }

        if !loopVideo {
            view.looper?.disableLooping()
        }

        // Need to determine how to show the controls in a way that doesn't add the big black background
        // perhaps I do that in the caching video player, I just need to determine how to hook into the class… perhaps
        // doing the old school delegate pattern is best here.

        return view
    }

    func updateUIView(_ uiView: VideoPlayerViewUIView, context: Context) { }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CachingVideoPlayer: View {
    let style: VideoComponentStyle
    // let repository = FileRepository() to do

    @State private var videoURL: URL?
    @State private var imageURL: URL?

    var body: some View {
        ZStack {

            if let imageURL {
//                ImageView
            }

            if let tempURL = videoURL {
                VideoPlayerView(
                    videoURL: tempURL,
                    shouldAutoPlay: style.autoplay,
                    shouldFillParent: style.contentMode == .fill,
                    showControls: style.showControls,
                    loopVideo: style.loop
                )
            }
        }
        .task {
            self.videoURL = self.style.url
//            self.imageURL = self.style.

//            if let cachedURL = try? await repository.getCachedURL(for: style.url) {
//                self.videoURL = cachedURL
//            } else {
//                self.videoURL = self.style.url // Fallback to manually load the video
//            }
        }
    }
}
