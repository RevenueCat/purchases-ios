//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoAutoplayHandlerTests.swift
//
//  Created by RevenueCat on 2/2/26.

import AVFoundation
import Combine
@testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)

class VideoAutoplayHandlerTests: TestCase {

    private var mockPlayer: MockPlaybackController!
    private var mockLifecycle: MockAppLifecycleObserver!
    private var handler: VideoAutoplayHandler!

    override func setUp() {
        super.setUp()
        mockPlayer = MockPlaybackController()
        mockLifecycle = MockAppLifecycleObserver()
    }

    override func tearDown() {
        handler = nil
        mockPlayer = nil
        mockLifecycle = nil
        super.tearDown()
    }

    func testResumesPlaybackWhenReturningFromBackgroundWhilePlaying() {
        // Given: Video was playing before backgrounding
        mockPlayer.isPlaybackRequested = true
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // When: App goes to background
        mockLifecycle.triggerWillResignActive()

        // And: App returns to foreground (player might have stopped)
        mockPlayer.isPlaybackRequested = false
        mockLifecycle.triggerDidBecomeActive()

        // Then: Playback should resume
        XCTAssertTrue(mockPlayer.playWasCalled, "Expected play() to be called when returning from background")
    }

    func testDoesNotResumePlaybackWhenWasNotPlayingBeforeBackground() {
        // Given: Video was paused before backgrounding
        mockPlayer.isPlaybackRequested = false
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // When: App goes to background and returns
        mockLifecycle.triggerWillResignActive()
        mockLifecycle.triggerDidBecomeActive()

        // Then: Playback should NOT resume
        XCTAssertFalse(
            mockPlayer.playWasCalled,
            "Expected play() to NOT be called when video was paused before background"
        )
    }

    func testTracksPlayingStateCorrectlyAcrossMultipleBackgroundCycles() {
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // First cycle: playing -> background -> foreground
        mockPlayer.isPlaybackRequested = true
        mockLifecycle.triggerWillResignActive()
        mockPlayer.isPlaybackRequested = false
        mockLifecycle.triggerDidBecomeActive()

        XCTAssertTrue(mockPlayer.playWasCalled)
        mockPlayer.playWasCalled = false

        // Second cycle: not playing -> background -> foreground
        mockPlayer.isPlaybackRequested = false
        mockLifecycle.triggerWillResignActive()
        mockLifecycle.triggerDidBecomeActive()

        XCTAssertFalse(mockPlayer.playWasCalled)
    }

    func testHandleWillResignActiveRecordsPlayingState() {
        mockPlayer.isPlaybackRequested = true
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // Directly test the handler method
        handler.handleWillResignActive()

        // Verify state was recorded by checking behavior on foreground
        mockPlayer.isPlaybackRequested = false
        handler.handleDidBecomeActive()

        XCTAssertTrue(mockPlayer.playWasCalled)
    }

    func testHandleDidBecomeActiveDoesNothingWhenWasNotPlaying() {
        mockPlayer.isPlaybackRequested = false
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        handler.handleWillResignActive()
        handler.handleDidBecomeActive()

        XCTAssertFalse(mockPlayer.playWasCalled)
    }

    func testDoesNotResumeAfterInvalidate() {
        // Given: video was playing and recorded before backgrounding
        mockPlayer.isPlaybackRequested = true
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )
        mockLifecycle.triggerWillResignActive()

        // When: the player is torn down (handler invalidated) before returning to foreground
        handler.invalidate()
        mockPlayer.isPlaybackRequested = false
        mockLifecycle.triggerDidBecomeActive()

        // Then: playback must NOT resume for a dismantled player
        XCTAssertFalse(
            mockPlayer.playWasCalled,
            "Expected play() to NOT be called after invalidate()"
        )
    }

    func testAutoplayWaitsUntilThePageBecomesActive() {
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle,
            isPlaybackEnabled: false
        )
        handler.play()
        XCTAssertFalse(mockPlayer.playWasCalled)
        handler.setPlaybackEnabled(true)
        XCTAssertTrue(mockPlayer.playWasCalled)
    }

    func testPageReactivationWaitsForTheAppToReturnToForeground() {
        mockPlayer.isPlaybackRequested = true
        handler = VideoAutoplayHandler(playbackController: mockPlayer, lifecycleObserver: mockLifecycle)
        mockLifecycle.triggerWillResignActive()
        mockPlayer.isPlaybackRequested = false
        handler.setPlaybackEnabled(false)
        handler.setPlaybackEnabled(true)
        XCTAssertFalse(mockPlayer.playWasCalled)
        mockLifecycle.triggerDidBecomeActive()
        XCTAssertTrue(mockPlayer.playWasCalled)
    }

    @MainActor
    func testPageReactivationResumesPlaybackWhileWaitingForMedia() {
        let player = AVPlayer()
        handler = VideoAutoplayHandler(playbackController: player, lifecycleObserver: mockLifecycle)
        player.play()
        XCTAssertEqual(player.rate, 1)
        XCTAssertNotEqual(player.timeControlStatus, .playing)
        handler.setPlaybackEnabled(false)
        XCTAssertEqual(player.rate, 0)
        handler.setPlaybackEnabled(true)
        XCTAssertEqual(player.rate, 1)
        player.pause()
    }

}

// MARK: - Mocks

private final class MockPlaybackController: VideoPlaybackController {

    var isPlaybackRequested: Bool = false
    var playWasCalled: Bool = false

    func play() {
        playWasCalled = true
        isPlaybackRequested = true
    }

    func pause() {
        isPlaybackRequested = false
    }

}

private final class MockAppLifecycleObserver: AppLifecycleObserving {

    private let willResignActiveSubject = PassthroughSubject<Void, Never>()
    private let didBecomeActiveSubject = PassthroughSubject<Void, Never>()

    var willResignActivePublisher: AnyPublisher<Void, Never> {
        willResignActiveSubject.eraseToAnyPublisher()
    }

    var didBecomeActivePublisher: AnyPublisher<Void, Never> {
        didBecomeActiveSubject.eraseToAnyPublisher()
    }

    func triggerWillResignActive() {
        willResignActiveSubject.send(())
    }

    func triggerDidBecomeActive() {
        didBecomeActiveSubject.send(())
    }

}

#endif
