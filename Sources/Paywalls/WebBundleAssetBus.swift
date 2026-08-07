//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleAssetBus.swift
//
//  Created by Jacob Zivan Rakidzich on 8/6/26.

import Combine
import Foundation

/// Publishes validated web-view entry URLs discovered during paywall cache warming.
///
/// Uses a `CurrentValueSubject` so late subscribers (e.g. RevenueCatUI's pool) still receive
/// the latest set even if they attach after the first warm.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@_spi(Internal) public actor WebBundleAssetBus {

    /// Shared bus used across modules. RevenueCatUI can subscribe without a `Purchases` instance.
    public static let shared = WebBundleAssetBus()

    private let subject: CurrentValueSubject<Set<URLWithValidation>, Never>

    /// Emits the latest set of web-view entry URLs. New subscribers immediately receive the
    /// current value (initially an empty set).
    public nonisolated let publisher: AnyPublisher<Set<URLWithValidation>, Never>

    /// Creates a bus. Prefer ``shared`` outside of tests.
    public init() {
        let subject = CurrentValueSubject<Set<URLWithValidation>, Never>([])
        self.subject = subject
        self.publisher = subject.eraseToAnyPublisher()
    }

    /// Replaces the current URL set and notifies subscribers.
    ///
    /// Callers are responsible for validating URLs (e.g. HTTPS) before publishing.
    public func publish(_ urls: Set<URLWithValidation>) {
        self.subject.send(urls)
    }

    /// Replaces the current URL set with an empty set and notifies subscribers.
    public func clear() {
        self.subject.send([])
    }

}
