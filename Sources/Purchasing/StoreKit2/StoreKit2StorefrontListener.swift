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

    func storefrontIdentifierDidChange(with storefront: StorefrontType)

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListener {

    private static let lastKnownStorefrontIdentifierKey = "com.revenuecat.userdefaults.lastKnownStorefrontIdentifierKey"

    private(set) var taskHandle: Task<Void, Never>? {
        didSet {
            if self.taskHandle != oldValue {
                oldValue?.cancel()
            }
        }
    }

    weak var delegate: StoreKit2StorefrontListenerDelegate?
    private let updates: AsyncStream<StorefrontType>
    private let userDefaults: UserDefaults

    convenience init(delegate: StoreKit2StorefrontListenerDelegate?, userDefaults: UserDefaults?) {
        self.init(
            delegate: delegate,
            updates: StoreKit.Storefront.updates.map(Storefront.init(sk2Storefront:)),
            userDefaults: userDefaults
        )
    }

    /// Creates a listener with an `AsyncSequence` of `StorefrontType`s
    /// By default `StoreKit.Storefront.updates` is used, but a custom one can be passed for testing.
    init<S: AsyncSequence>(
        delegate: StoreKit2StorefrontListenerDelegate?,
        updates: S,
        userDefaults: UserDefaults?
    ) where S.Element == StorefrontType {
        self.delegate = delegate
        self.updates = updates.toAsyncStream()
        self.userDefaults = userDefaults ?? UserDefaults.computeDefault()
    }

    func listenForStorefrontChanges() {
        self.taskHandle = Task(priority: .utility) { [weak self, updates = self.updates] in
            for await storefront in updates {
                guard let delegate = self?.delegate else { break }

                // Only emit if this is an actual change from the last known storefront
                if self?.shouldEmitStorefrontChange(storefront) == true {

                    // Update the last known storefront
                    self?.updateLastKnownStorefrontIdentifier(storefront.identifier)

                    await MainActor.run { @Sendable in
                        delegate.storefrontIdentifierDidChange(with: storefront)
                    }
                }
            }
        }
    }

    /// On macOS SK2 will emit a storefront update right away when subscribing to
    /// updates, even when the storefront hasn't changed
    /// by storing the last known storefront identifier in UserDefaults we're ignoring this update
    /// unless the storefront identifier has actually changed
    private func shouldEmitStorefrontChange(_ storefront: StorefrontType) -> Bool {
        guard let lastIdentifier = self.userDefaults.string(forKey: Self.lastKnownStorefrontIdentifierKey) else {
            return true
        }

        return storefront.identifier != lastIdentifier
    }

    private func updateLastKnownStorefrontIdentifier(_ identifier: String) {
        self.userDefaults.set(identifier, forKey: Self.lastKnownStorefrontIdentifierKey)
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }

}
