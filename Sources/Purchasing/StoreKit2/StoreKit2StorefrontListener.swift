//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2StorefrontListener.swift
//
//  Created by Juanpe Catalán on 5/5/22.

import Foundation
import StoreKit

protocol StoreKit2StorefrontListenerDelegate: AnyObject, Sendable {

    func storefrontDidUpdate(with storefront: StorefrontType)

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListener {

    private(set) var taskHandle: Task<Void, Never>? {
        didSet {
            if self.taskHandle != oldValue {
                oldValue?.cancel()
            }
        }
    }

    weak var delegate: StoreKit2StorefrontListenerDelegate?
    private let updates: AsyncStream<StorefrontType>

    convenience init(delegate: StoreKit2StorefrontListenerDelegate?) {
        self.init(
            delegate: delegate,
            updates: StoreKit.Storefront.updates.map(Storefront.init(sk2Storefront:))
        )
    }

    /// Creates a listener with an `AsyncSequence` of `StorefrontType`s
    /// By default `StoreKit.Storefront.updates` is used, but a custom one can be passed for testing.
    init<S: AsyncSequence>(
        delegate: StoreKit2StorefrontListenerDelegate?,
        updates: S
    ) where S.Element == StorefrontType {
        self.delegate = delegate
        self.updates = updates.toAsyncStream()
    }

    func listenForStorefrontChanges() {
        self.taskHandle = Task(priority: .utility) { [weak self, updates = self.updates] in
            for await storefront in updates {
                guard let delegate = self?.delegate else { break }
                await MainActor.run { @Sendable in
                    delegate.storefrontDidUpdate(with: storefront)
                }
            }
        }
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension AsyncSequence {

    func toAsyncStream() -> AsyncStream<Element> {
        var asyncIterator = self.makeAsyncIterator()
        return AsyncStream<Element> {
            try? await asyncIterator.next()
        }
    }

}
