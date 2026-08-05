//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoPlayerViewTests.swift
//
//  Created by RevenueCat.
//

import AVFoundation
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class VideoPlayerViewTests: TestCase {

    private static let videoURL = URL(string: "https://assets.revenuecat.com/video.mp4")!

    // MARK: - Controls path (AVPlayerViewController)

    // The controls path renders with AVPlayerViewController. Handing it an AVPlayerLooper-driven
    // AVQueuePlayer is what crashes on teardown (NSInternalInconsistencyException on
    // currentItem.status, issue #6985), so a looping controls video must loop via a single-item
    // AVPlayer + seek and must never build an AVQueuePlayer.
    func testControlsLoopingVideoDoesNotUseQueuePlayer() {
        let view = VideoPlayerUIView(
            videoURL: Self.videoURL,
            shouldAutoPlay: false,
            contentMode: .fill,
            loopVideo: true,
            muteAudio: true
        )

        let coordinator = view.makeCoordinator()

        XCTAssertFalse(coordinator.player is AVQueuePlayer)
    }

    func testControlsNonLoopingVideoDoesNotUseQueuePlayer() {
        let view = VideoPlayerUIView(
            videoURL: Self.videoURL,
            shouldAutoPlay: false,
            contentMode: .fill,
            loopVideo: false,
            muteAudio: true
        )

        let coordinator = view.makeCoordinator()

        XCTAssertFalse(coordinator.player is AVQueuePlayer)
    }

    // MARK: - No-controls path (AVPlayerLayer)

    // The no-controls path renders via an AVPlayerLayer-backed view, which has no internal
    // AVPlayerController and therefore never registers the observers that crash. It can safely
    // drive looping with an AVQueuePlayer + AVPlayerLooper.
    func testNoControlsLoopingVideoUsesQueuePlayer() {
        let view = VideoPlayerLayerView(
            videoURL: Self.videoURL,
            shouldAutoPlay: false,
            contentMode: .fill,
            loopVideo: true,
            muteAudio: true
        )

        let coordinator = view.makeCoordinator()

        XCTAssertTrue(coordinator.player is AVQueuePlayer)
    }

    func testNoControlsNonLoopingVideoUsesSingleItemPlayer() {
        let view = VideoPlayerLayerView(
            videoURL: Self.videoURL,
            shouldAutoPlay: false,
            contentMode: .fill,
            loopVideo: false,
            muteAudio: true
        )

        let coordinator = view.makeCoordinator()

        XCTAssertFalse(coordinator.player is AVQueuePlayer)
    }

    // MARK: - Layer backing

    // The no-controls view must be backed by an AVPlayerLayer (not an AVPlayerViewController), so
    // AVKit's internal AVPlayerController and its crashing currentItem.* observers never exist.
    func testPlayerLayerBackedViewIsBackedByAVPlayerLayer() {
        XCTAssertTrue(PlayerLayerBackedView.layerClass is AVPlayerLayer.Type)

        let view = PlayerLayerBackedView()
        XCTAssertTrue(view.layer is AVPlayerLayer)
        XCTAssertTrue(view.playerLayer === view.layer)
    }

}

#endif
