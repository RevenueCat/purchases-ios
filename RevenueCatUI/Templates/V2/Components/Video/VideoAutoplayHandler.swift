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
    var isPlaying: Bool { get }
    func play()
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
    private var cancellables = Set<AnyCancellable>()

    init(playbackController: VideoPlaybackController, lifecycleObserver: AppLifecycleObserving) {
        self.playbackController = playbackController

        lifecycleObserver.willResignActivePublisher
            .sink { [weak self] in self?.handleWillResignActive() }
            .store(in: &cancellables)

        lifecycleObserver.didBecomeActivePublisher
            .sink { [weak self] in self?.handleDidBecomeActive() }
            .store(in: &cancellables)
    }

    func handleWillResignActive() {
        wasPlayingBeforeBackground = playbackController.isPlaying
    }

    func handleDidBecomeActive() {
        if wasPlayingBeforeBackground {
            playbackController.play()
        }
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
