//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoAudioSessionHandlerTests.swift
//
//  Created by RevenueCat on 3/6/26.

import AVFoundation
@testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)

class VideoAudioSessionHandlerTests: TestCase {

    func testSetsPlaybackCategoryOnInit() {
        let mockSession = MockAudioSession()

        _ = VideoAudioSessionHandler(audioSession: mockSession)

        XCTAssertEqual(mockSession.category, .playback)
        XCTAssertEqual(mockSession.mode, .default)
        XCTAssertEqual(mockSession.categoryOptions, .mixWithOthers)
    }

    func testSavesPreviousAudioSessionState() {
        let mockSession = MockAudioSession(
            category: .record,
            mode: .voiceChat,
            options: .duckOthers
        )

        _ = VideoAudioSessionHandler(audioSession: mockSession)

        // After init, category should be .playback
        XCTAssertEqual(mockSession.category, .playback)

        // But the previous state should be saved for restoration
        XCTAssertEqual(mockSession.setCategoryCalls.first?.category, .playback)
    }

    func testRestoresPreviousAudioSessionOnDeinit() {
        let mockSession = MockAudioSession(
            category: .record,
            mode: .voiceChat,
            options: .duckOthers
        )

        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: mockSession)
        XCTAssertNotNil(handler)

        // Trigger deinit
        handler = nil

        // Should have two setCategory calls: one for .playback on init, one to restore on deinit
        XCTAssertEqual(mockSession.setCategoryCalls.count, 2)

        let restoreCall = mockSession.setCategoryCalls[1]
        XCTAssertEqual(restoreCall.category, .record)
        XCTAssertEqual(restoreCall.mode, .voiceChat)
        XCTAssertEqual(restoreCall.options, .duckOthers)
    }

    func testRestoresDefaultCategoryOnDeinit() {
        let mockSession = MockAudioSession()

        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: mockSession)
        XCTAssertNotNil(handler)

        handler = nil

        XCTAssertEqual(mockSession.setCategoryCalls.count, 2)

        let restoreCall = mockSession.setCategoryCalls[1]
        XCTAssertEqual(restoreCall.category, .soloAmbient)
        XCTAssertEqual(restoreCall.mode, .default)
        XCTAssertEqual(restoreCall.options, [])
    }

    func testHandlesSetCategoryError() {
        let mockSession = MockAudioSession()
        mockSession.shouldThrow = true

        // Should not crash when setCategory throws
        _ = VideoAudioSessionHandler(audioSession: mockSession)

        XCTAssertEqual(mockSession.setCategoryCalls.count, 1)
        // Category should remain unchanged since setCategory threw
        XCTAssertEqual(mockSession.category, .soloAmbient)
    }

}

// MARK: - Mock

private final class MockAudioSession: AudioSessionConfiguring {

    struct SetCategoryCall {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    private(set) var category: AVAudioSession.Category
    private(set) var mode: AVAudioSession.Mode
    private(set) var categoryOptions: AVAudioSession.CategoryOptions

    var shouldThrow = false
    private(set) var setCategoryCalls: [SetCategoryCall] = []

    init(
        category: AVAudioSession.Category = .soloAmbient,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = []
    ) {
        self.category = category
        self.mode = mode
        self.categoryOptions = options
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        setCategoryCalls.append(SetCategoryCall(category: category, mode: mode, options: options))

        if shouldThrow {
            throw NSError(domain: "MockAudioSessionError", code: 1)
        }

        self.category = category
        self.mode = mode
        self.categoryOptions = options
    }

}

#endif
