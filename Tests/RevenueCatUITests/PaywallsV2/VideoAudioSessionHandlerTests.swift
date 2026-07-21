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

import AVFoundation
@testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)

final class VideoAudioSessionHandlerTests: TestCase {

    func testSetsPlaybackCategoryWithMixing() {
        let audioSession = MockAudioSession()

        let handler = VideoAudioSessionHandler(audioSession: audioSession)

        XCTAssertEqual(audioSession.configuration, .playbackWithMixing)
        XCTAssertNotNil(handler)
    }

    func testRestoresPreviousConfigurationWhenReleased() {
        let previousConfiguration = Configuration(
            category: .record,
            mode: .voiceChat,
            options: [.duckOthers]
        )
        let audioSession = MockAudioSession(configuration: previousConfiguration)

        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(handler)
        handler = nil

        XCTAssertEqual(audioSession.configuration, previousConfiguration)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 2)
    }

    func testRestoresPreviousConfigurationAfterLastHandlerIsReleased() {
        let previousConfiguration = Configuration(category: .playback, mode: .default, options: [])
        let audioSession = MockAudioSession(configuration: previousConfiguration)

        var firstHandler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        var secondHandler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(firstHandler)
        XCTAssertNotNil(secondHandler)
        firstHandler = nil

        XCTAssertEqual(audioSession.configuration, .playbackWithMixing)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 1)

        secondHandler = nil

        XCTAssertEqual(audioSession.configuration, previousConfiguration)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 2)
    }

    func testUnregisteredHandlerDoesNotRestoreAnotherHandlerConfiguration() {
        let audioSession = MockAudioSession(configuration: .playbackWithMixing)
        var unregisteredHandler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(unregisteredHandler)

        let previousConfiguration = Configuration(category: .record, mode: .voiceChat, options: [])
        audioSession.configuration = previousConfiguration
        var registeredHandler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(registeredHandler)

        unregisteredHandler = nil

        XCTAssertEqual(audioSession.configuration, .playbackWithMixing)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 1)

        registeredHandler = nil

        XCTAssertEqual(audioSession.configuration, previousConfiguration)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 2)
    }

    func testPreservesMixingWhenExternalAudioIsPlaying() {
        let previousConfiguration = Configuration(category: .playback, mode: .default, options: [])
        let audioSession = MockAudioSession(configuration: previousConfiguration)
        audioSession.secondaryAudioShouldBeSilencedHint = true

        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(handler)
        handler = nil

        XCTAssertEqual(audioSession.configuration, .playbackWithMixing)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 2)
    }

    func testDoesNotOverwriteHostConfigurationChangedDuringVideoPlayback() {
        let audioSession = MockAudioSession()
        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(handler)
        let hostConfiguration = Configuration(category: .playAndRecord, mode: .videoChat, options: [.allowBluetoothHFP])
        audioSession.configuration = hostConfiguration

        handler = nil

        XCTAssertEqual(audioSession.configuration, hostConfiguration)
        XCTAssertEqual(audioSession.setCategoryCalls.count, 1)
    }

    func testDoesNotRestoreWhenConfiguringPlaybackFails() {
        let audioSession = MockAudioSession()
        audioSession.shouldThrow = true

        var handler: VideoAudioSessionHandler? = VideoAudioSessionHandler(audioSession: audioSession)
        XCTAssertNotNil(handler)
        handler = nil

        XCTAssertEqual(audioSession.setCategoryCalls.count, 1)
        XCTAssertEqual(audioSession.configuration, .default)
    }

}

private final class MockAudioSession: AudioSessionConfiguring {

    var configuration: Configuration
    var shouldThrow = false
    private(set) var setCategoryCalls: [Configuration] = []

    var category: AVAudioSession.Category { configuration.category }
    var mode: AVAudioSession.Mode { configuration.mode }
    var categoryOptions: AVAudioSession.CategoryOptions { configuration.options }
    var secondaryAudioShouldBeSilencedHint = false

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        let configuration = Configuration(category: category, mode: mode, options: options)
        setCategoryCalls.append(configuration)

        if shouldThrow {
            throw NSError(domain: "MockAudioSession", code: 1)
        }

        self.configuration = configuration
    }

}

private struct Configuration: Equatable {

    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let options: AVAudioSession.CategoryOptions

    static let `default` = Self(category: .soloAmbient, mode: .default, options: [])
    static let playbackWithMixing = Self(category: .playback, mode: .default, options: [.mixWithOthers])

}

#endif
