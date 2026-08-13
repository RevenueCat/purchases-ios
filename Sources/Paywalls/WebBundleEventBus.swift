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
// swiftlint:disable missing_docs

@preconcurrency import Combine
import Foundation

/// Publishes validated web-view entry URLs discovered during paywall cache warming,
/// and a best-effort signal for live web views to drop in-memory `WKWebView`s on logout.
///
/// Events are pulses: late subscribers do not receive prior values, so a new web view
/// created after logout will not immediately tear itself down.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@_spi(Internal) public actor WebBundleEventBus {

    public static let shared = WebBundleEventBus()

    private let subject: PassthroughSubject<WebBundleEvent, Never>

    public nonisolated let publisher: AnyPublisher<WebBundleEvent, Never>

    public init() {
        let subject = PassthroughSubject<WebBundleEvent, Never>()
        self.subject = subject
        self.publisher = subject.eraseToAnyPublisher()
    }

    /// Notifies subscribers of a new URL set.
    public func publish(_ urls: Set<URLWithValidation>) {
        self.subject.send(.receivedAssetURLs(urls))
    }

    /// Notifies subscribers that the URL set is empty.
    public func empty() {
        self.subject.send(.empty)
    }

    /// Notifies live observers to clear their caches.
    public func clearCache() {
        self.subject.send(.cacheClearRequested)
    }

}

@_spi(Internal) public enum WebBundleEvent: Equatable, Sendable {
    case empty
    case receivedAssetURLs(Set<URLWithValidation>)
    case cacheClearRequested
}
