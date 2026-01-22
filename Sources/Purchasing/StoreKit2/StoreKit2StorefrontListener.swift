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

    func storefrontIdentifierOrCountryDidChange(with storefront: StorefrontType)

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListener {

    private static let lastKnownStorefrontKey = "com.revenuecat.userdefaults.lastKnownStorefrontKey"

    private(set) var taskHandle: Task<Void, Never>? {
        didSet {
            if self.taskHandle != oldValue {
                oldValue?.cancel()
            }
        }
    }

    weak var delegate: StoreKit2StorefrontListenerDelegate?
    private let updates: AsyncStream<StorefrontType>
    private let userDefaults: SynchronizedUserDefaults

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
        self.userDefaults = SynchronizedUserDefaults(userDefaults: userDefaults ?? UserDefaults.computeDefault())
    }

    func listenForStorefrontChanges() {
        self.taskHandle = Task(priority: .utility) { [weak self, updates = self.updates] in
            for await storefront in updates {
                guard let delegate = self?.delegate else { break }

                // Only emit if this is an actual change from the last known storefront
                if self?.shouldEmitStorefrontChange(storefront) == true {

                    // Update the last known storefront
                    self?.updateLastKnownStorefront(storefront)

                    OperationDispatcher.dispatchOnMainActor {
                        delegate.storefrontIdentifierOrCountryDidChange(with: storefront)
                    }
                }
            }
        }
    }

    /// On macOS SK2 will emit a storefront update right away when subscribing to
    /// updates, even when the storefront hasn't changed
    /// by storing the last known storefront in UserDefaults we're ignoring this update
    /// unless the storefront (identifier or country) has actually changed
    private func shouldEmitStorefrontChange(_ storefront: StorefrontType) -> Bool {
        let lastKnownStorefrontValue = self.userDefaults.read {
            $0.string(forKey: Self.lastKnownStorefrontKey)
        }

        return lastKnownStorefrontValue != Self.userDefaultsValue(for: storefront)
    }

    private func updateLastKnownStorefront(_ storefront: StorefrontType) {
        let value = Self.userDefaultsValue(for: storefront)
        self.userDefaults.write {
            $0.set(value, forKey: Self.lastKnownStorefrontKey)
        }
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }

    private static func userDefaultsValue(for storefront: StorefrontType) -> String {
        storefront.identifier + "." + storefront.countryCode
    }
}
