//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleEventBus.swift
//
//  Created by Jacob Zivan Rakidzich on 8/6/26.

import Combine
import Foundation

/// Publishes validated web-view entry URLs discovered during paywall cache warming.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor WebBundleEventBus {

    static let shared = WebBundleEventBus()

    private let subject: CurrentValueSubject<WebBundleEvent, Never>

    nonisolated let publisher: AnyPublisher<WebBundleEvent, Never>

    init() {
        let subject = CurrentValueSubject<WebBundleEvent, Never>(.empty)
        self.subject = subject
        self.publisher = subject.eraseToAnyPublisher()
    }

    /// Replaces the current URL set and notifies subscribers.
    func publish(_ urls: Set<URLWithValidation>) {
        self.subject.send(.receivedAssetURLs(urls))
    }

    /// Sets the state back to empty
    func empty() {
        self.subject.send(.empty)
    }

    /// Notifies observers to clear their caches
    func clearCache() {
        self.subject.send(.cacheClearRequested)
    }

}

enum WebBundleEvent: Equatable, Sendable {
    case empty
    case receivedAssetURLs(Set<URLWithValidation>)
    case cacheClearRequested
}
