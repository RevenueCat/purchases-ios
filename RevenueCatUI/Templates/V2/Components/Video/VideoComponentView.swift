//
//  VideoComponentView.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

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
            let url = URL(string: style.videoID)!
            CachingVideoPlayer(
                url: url,
                shouldAutoPlay: style.autoplay,
                shouldShowControls: style.showControls
            )
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

// Custom UIView for the video player
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

        // Create the player item and looper for seamless looping
        let playerItem = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)

        // Mute the video (common for backgrounds)
        queuePlayer?.isMuted = true

        // to do: Autoplay based on input
        queuePlayer?.play()

        // to do: Determine aspect ratio based on input
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.videoGravity = .resizeAspect
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

// SwiftUI wrapper for the UIView
struct VideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    var shouldAutoPlay = true
    // to do: rename this and make it the aspect ratio type instead
    var shouldFillParent: Bool = false
    var showControls: Bool = false
    var loopVideo: Bool = false

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> VideoPlayerViewUIView {
        let view = VideoPlayerViewUIView(url: videoURL)
        view.playerLayer?.videoGravity = shouldFillParent ? .resizeAspectFill : .resizeAspect

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

struct CachingVideoPlayer: View {
    let url: URL
    var shouldAutoPlay = true
    var shouldShowControls = false
    // to do: rename this and make it the aspect ratio type instead
    var shouldFillParent: Bool = false
    var loopVideo: Bool = false

    @State private var loadFromURL: URL?

    var body: some View {
        VStack {
            if let tempURL = loadFromURL {
                VideoPlayerView(
                    videoURL: tempURL,
                    shouldAutoPlay: shouldAutoPlay,
                    shouldFillParent: shouldFillParent
                )
            } else {
                Color.clear
                    .onAppear {
                        FileRepository.shared.getVideoURL(for: url) { url in
                            self.loadFromURL = url
                        }
                    }
            }
        }
    }
}
