//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoAudioSessionHandler.swift
//

import AVFoundation
@_spi(Internal) import RevenueCat

#if canImport(UIKit) && !os(watchOS)

protocol AudioSessionConfiguring: AnyObject {

    var category: AVAudioSession.Category { get }
    var mode: AVAudioSession.Mode { get }
    var categoryOptions: AVAudioSession.CategoryOptions { get }
    var secondaryAudioShouldBeSilencedHint: Bool { get }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws

}

extension AVAudioSession: AudioSessionConfiguring {}

/// Configures the app's shared audio session while one or more paywall videos are alive.
///
/// The playback category keeps the host app's background audio working, while `mixWithOthers`
/// prevents the paywall video from interrupting audio played by another app. The initial session
/// configuration is restored only after the last video is released.
///
/// Isolated to the main actor: the SwiftUI video coordinators that own it are created and
/// dismantled on the main actor, so the shared `states` map is accessed single-threaded and needs
/// no locking. Registration happens in `init`; the owner must call `release()` from its teardown.
@MainActor
final class VideoAudioSessionHandler {

    private static var states: [ObjectIdentifier: State] = [:]

    private let audioSession: AudioSessionConfiguring
    private let sessionIdentifier: ObjectIdentifier
    private var isRegistered = false

    init(audioSession: AudioSessionConfiguring = AVAudioSession.sharedInstance()) {
        self.audioSession = audioSession
        self.sessionIdentifier = ObjectIdentifier(audioSession)

        if let state = Self.states[sessionIdentifier] {
            state.handlerCount += 1
            self.isRegistered = true
            return
        }

        let previousConfiguration = Configuration(audioSession: audioSession)
        let playbackConfiguration = Configuration.playbackWithMixing

        guard previousConfiguration != playbackConfiguration else {
            return
        }

        do {
            try audioSession.setCategory(
                playbackConfiguration.category,
                mode: playbackConfiguration.mode,
                options: playbackConfiguration.options
            )
            Self.states[sessionIdentifier] = State(
                previousConfiguration: previousConfiguration,
                handlerCount: 1
            )
            self.isRegistered = true
        } catch {
            Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
        }
    }

    /// Releases this handler's claim on the shared audio session, restoring the original
    /// configuration once the last live handler is released. Idempotent, so a coordinator can call
    /// it from teardown without worrying about being torn down twice.
    func release() {
        guard isRegistered, let state = Self.states[sessionIdentifier] else {
            return
        }
        self.isRegistered = false

        state.handlerCount -= 1
        guard state.handlerCount == 0 else {
            return
        }
        Self.states[sessionIdentifier] = nil

        // Do not overwrite an audio session configuration the host app set while the paywall
        // was being displayed.
        guard Configuration(audioSession: audioSession) == .playbackWithMixing else {
            return
        }

        guard let restorationConfiguration = state.previousConfiguration.restoringMixingIfNeeded(
            externalAudioIsPlaying: audioSession.secondaryAudioShouldBeSilencedHint
        ) else {
            return
        }

        do {
            try audioSession.setCategory(
                restorationConfiguration.category,
                mode: restorationConfiguration.mode,
                options: restorationConfiguration.options
            )
        } catch {
            Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
        }
    }

}

private extension VideoAudioSessionHandler {

    final class State {

        let previousConfiguration: Configuration
        var handlerCount: Int

        init(previousConfiguration: Configuration, handlerCount: Int) {
            self.previousConfiguration = previousConfiguration
            self.handlerCount = handlerCount
        }

    }

    struct Configuration: Equatable {

        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions

        init(audioSession: AudioSessionConfiguring) {
            self.category = audioSession.category
            self.mode = audioSession.mode
            self.options = audioSession.categoryOptions
        }

        static let playbackWithMixing = Self(
            category: .playback,
            mode: .default,
            options: [.mixWithOthers]
        )

        /// Returns `nil` when restoring this configuration would interrupt audio from another app.
        func restoringMixingIfNeeded(externalAudioIsPlaying: Bool) -> Self? {
            guard externalAudioIsPlaying else {
                return self
            }

            switch category {
            case .playback, .playAndRecord, .multiRoute:
                return Self(category: category, mode: mode, options: options.union(.mixWithOthers))
            default:
                return nil
            }
        }

        private init(
            category: AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            options: AVAudioSession.CategoryOptions
        ) {
            self.category = category
            self.mode = mode
            self.options = options
        }

    }

}

#endif
