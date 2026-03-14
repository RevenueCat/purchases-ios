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
//  Created by RevenueCat on 3/6/26.

import AVFoundation
import RevenueCat

#if canImport(UIKit) && !os(watchOS)

// MARK: - Protocol for testability

protocol AudioSessionConfiguring: AnyObject {
    var category: AVAudioSession.Category { get }
    var mode: AVAudioSession.Mode { get }
    var categoryOptions: AVAudioSession.CategoryOptions { get }
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
}

extension AVAudioSession: AudioSessionConfiguring {}

// MARK: - VideoAudioSessionHandler

/// Manages the audio session category for video playback.
/// Saves the previous audio session state on activation and restores it on deinit.
/// Extracted from the Coordinator for testability.
final class VideoAudioSessionHandler {

    private let audioSession: AudioSessionConfiguring
    private let previousCategory: AVAudioSession.Category
    private let previousMode: AVAudioSession.Mode
    private let previousOptions: AVAudioSession.CategoryOptions

    init(audioSession: AudioSessionConfiguring = AVAudioSession.sharedInstance()) {
        self.audioSession = audioSession
        self.previousCategory = audioSession.category
        self.previousMode = audioSession.mode
        self.previousOptions = audioSession.categoryOptions

        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
        }
    }

    deinit {
        do {
            try audioSession.setCategory(
                previousCategory,
                mode: previousMode,
                options: previousOptions
            )
        } catch {
            Logger.warning(Strings.video_failed_to_set_audio_session_category(error))
        }
    }

}

#endif
