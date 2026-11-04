//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoAutoplayHandler.swift
//
//  Created by RevenueCat on 2/2/26.

import Combine
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Protocols for testability

protocol VideoPlaybackController: AnyObject {
    var isPlaybackRequested: Bool { get }
    func play()
    func pause()
}

protocol AppLifecycleObserving {
    var willResignActivePublisher: AnyPublisher<Void, Never> { get }
    var didBecomeActivePublisher: AnyPublisher<Void, Never> { get }
}

// MARK: - VideoAutoplayHandler

/// Handles pausing and resuming video playback when the app transitions between active and background states.
/// Extracted from the Coordinator for testability.
final class VideoAutoplayHandler {

    private let playbackController: VideoPlaybackController
    private var wasPlayingBeforeBackground = false
    private var wasPlayingBeforeDisabled = false
    private var isAppActive = true
    private(set) var isPlaybackEnabled: Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        playbackController: VideoPlaybackController,
        lifecycleObserver: AppLifecycleObserving,
        isPlaybackEnabled: Bool = true
    ) {
        self.playbackController = playbackController
        self.isPlaybackEnabled = isPlaybackEnabled

        lifecycleObserver.willResignActivePublisher
            .sink { [weak self] in self?.handleWillResignActive() }
            .store(in: &cancellables)

        lifecycleObserver.didBecomeActivePublisher
            .sink { [weak self] in self?.handleDidBecomeActive() }
            .store(in: &cancellables)
    }

    func play() {
        guard isPlaybackEnabled else {
            wasPlayingBeforeDisabled = true
            return
        }
        guard isAppActive else {
            wasPlayingBeforeBackground = true
            return
        }
        playbackController.play()
    }

    func setPlaybackEnabled(_ enabled: Bool) {
        guard enabled != isPlaybackEnabled else { return }
        isPlaybackEnabled = enabled
        if enabled {
            if wasPlayingBeforeDisabled { play() }
            wasPlayingBeforeDisabled = false
        } else {
            wasPlayingBeforeDisabled = playbackController.isPlaybackRequested || wasPlayingBeforeBackground
            wasPlayingBeforeBackground = false
            playbackController.pause()
        }
    }

    func handleWillResignActive() {
        isAppActive = false
        if isPlaybackEnabled {
            wasPlayingBeforeBackground = playbackController.isPlaybackRequested
        }
    }

    func handleDidBecomeActive() {
        isAppActive = true
        if wasPlayingBeforeBackground { play() }
        wasPlayingBeforeBackground = false
    }

    /// Stops responding to lifecycle transitions. Call when the player is being torn down so a
    /// later `didBecomeActive` can't resume a player that should stay stopped.
    func invalidate() {
        cancellables.removeAll()
        wasPlayingBeforeBackground = false
        wasPlayingBeforeDisabled = false
        isPlaybackEnabled = false
    }

}

// MARK: - Production implementations

struct SystemAppLifecycleObserver: AppLifecycleObserving {

    var willResignActivePublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var didBecomeActivePublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

}

#endif
