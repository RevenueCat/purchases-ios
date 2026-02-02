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
        mockPlayer.isPlaying = true
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // When: App goes to background
        mockLifecycle.triggerWillResignActive()

        // And: App returns to foreground (player might have stopped)
        mockPlayer.isPlaying = false
        mockLifecycle.triggerDidBecomeActive()

        // Then: Playback should resume
        XCTAssertTrue(mockPlayer.playWasCalled, "Expected play() to be called when returning from background")
    }

    func testDoesNotResumePlaybackWhenWasNotPlayingBeforeBackground() {
        // Given: Video was paused before backgrounding
        mockPlayer.isPlaying = false
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
        mockPlayer.isPlaying = true
        mockLifecycle.triggerWillResignActive()
        mockPlayer.isPlaying = false
        mockLifecycle.triggerDidBecomeActive()

        XCTAssertTrue(mockPlayer.playWasCalled)
        mockPlayer.playWasCalled = false

        // Second cycle: not playing -> background -> foreground
        mockPlayer.isPlaying = false
        mockLifecycle.triggerWillResignActive()
        mockLifecycle.triggerDidBecomeActive()

        XCTAssertFalse(mockPlayer.playWasCalled)
    }

    func testHandleWillResignActiveRecordsPlayingState() {
        mockPlayer.isPlaying = true
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        // Directly test the handler method
        handler.handleWillResignActive()

        // Verify state was recorded by checking behavior on foreground
        mockPlayer.isPlaying = false
        handler.handleDidBecomeActive()

        XCTAssertTrue(mockPlayer.playWasCalled)
    }

    func testHandleDidBecomeActiveDoesNothingWhenWasNotPlaying() {
        mockPlayer.isPlaying = false
        handler = VideoAutoplayHandler(
            playbackController: mockPlayer,
            lifecycleObserver: mockLifecycle
        )

        handler.handleWillResignActive()
        handler.handleDidBecomeActive()

        XCTAssertFalse(mockPlayer.playWasCalled)
    }

}

// MARK: - Mocks

private final class MockPlaybackController: VideoPlaybackController {

    var isPlaying: Bool = false
    var playWasCalled: Bool = false

    func play() {
        playWasCalled = true
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
