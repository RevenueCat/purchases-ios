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

    private let model: VideoComponentViewModel
    private let style: VideoComponentStyle

    init(
        model: VideoComponentViewModel,
        style: VideoComponentStyle
    ) {
        self.model = model
        self.style = style
    }

    var body: some View {
        let url = URL(string: self.style.videoID)!
        CachingVideoPlayer(
            url: url,
            shouldAutoPlay: self.style.autoplay,
            shouldShowControls: self.style.showControls
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

// Custom UIView for the video player
class VideoPlayerViewUIView: UIView {
    var playerLayer: AVPlayerLayer?
    var queuePlayer: AVQueuePlayer?
    var looper: AVPlayerLooper?

    required init(url: URL) {
        super.init(frame: .zero)

        // Create the queue player and layer
        queuePlayer = AVQueuePlayer()
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspectFill
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }

        // Create the player item and looper for seamless looping
        let playerItem = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)

        // Mute the video (common for backgrounds)
        queuePlayer?.isMuted = true

        // Autoplay
        queuePlayer?.play()

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
        queuePlayer?.pause()
        queuePlayer = nil
        playerLayer?.removeFromSuperlayer()
        NotificationCenter.default.removeObserver(self)
    }
}

// SwiftUI wrapper for the UIView
struct VideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    var shouldAutoPlay = true
    var shouldFillParent: Bool = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeUIView(context: Context) -> VideoPlayerViewUIView {
        let view = VideoPlayerViewUIView(url: videoURL)
        view.playerLayer?.videoGravity = shouldFillParent ? .resizeAspectFill : .resizeAspect

        if shouldAutoPlay && !reduceMotion {
            view.queuePlayer?.play()
        }

        // Need to determine how to show the controls in a way that doesn't add the big black background

        return view
    }

    func updateUIView(_ uiView: VideoPlayerViewUIView, context: Context) {
        // No updates needed
    }
}

struct CachingVideoPlayer: View {
    let url: URL
    var shouldAutoPlay = true
    var shouldShowControls = false
    var shouldFillParent: Bool = false

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
                        VideoRepository.shared.getVideoURL(for: url) { url in
                            self.loadFromURL = url
                        }
                    }
            }
        }
    }
}
