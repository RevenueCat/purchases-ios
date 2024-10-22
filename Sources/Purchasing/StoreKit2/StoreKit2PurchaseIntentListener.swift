//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2PurchaseIntentListener.swift
//
//  Created by Will Taylor on 10/10/24.

import StoreKit

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
protocol StoreKit2PurchaseIntentListenerDelegate: AnyObject, Sendable {

    func storeKit2PurchaseIntentListener(
        _ listener: StoreKit2PurchaseIntentListenerType,
        purchaseIntent: StorePurchaseIntent
    ) async

}

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
protocol StoreKit2PurchaseIntentListenerType: Sendable {

    func listenForPurchaseIntents() async

    func set(delegate: StoreKit2PurchaseIntentListenerDelegate) async
}

/// Observes `StoreKit.PurchaseIntent.intents`, which receives purchase intents, which indicate that
/// subscriber customer initiated a purchase outside of the app, for the app to complete.
@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
actor StoreKit2PurchaseIntentListener: StoreKit2PurchaseIntentListenerType {

    private(set) var taskHandle: Task<Void, Never>?

    private weak var delegate: StoreKit2PurchaseIntentListenerDelegate?

    // We can't directly store instances of `AsyncStream`, since that causes runtime crashes when
    // loading this type in iOS <= 15, even with @available checks correctly in place.
    // See https://openradar.appspot.com/radar?id=4970535809187840 / https://github.com/apple/swift/issues/58099
    private let _updates: Box<AsyncStream<StorePurchaseIntent>>?

    var updates: AsyncStream<StorePurchaseIntent>? {
        return self._updates?.value
    }

    init(delegate: StoreKit2PurchaseIntentListenerDelegate? = nil) {

        #if compiler(>=5.10)
        let storePurchaseIntentSequence = StoreKit.PurchaseIntent.intents.map { purchaseIntent in
            return StorePurchaseIntent(purchaseIntent: purchaseIntent)
        }.toAsyncStream()
        #else
        let storePurchaseIntentSequence: AsyncStream<StorePurchaseIntent>? = nil
        #endif

        self.init(
            delegate: delegate,
            updates: storePurchaseIntentSequence
        )
    }

    /// Creates a listener with an `AsyncSequence` of `VerificationResult<Transaction>`s
    /// By default `StoreKit.Transaction.updates` is used, but a custom one can be passed for testing.
    init<S: AsyncSequence>(
        delegate: StoreKit2PurchaseIntentListenerDelegate? = nil,
        updates: S?
    ) where S.Element == StorePurchaseIntent {
        self.delegate = delegate
        if let updates {
            self._updates = .init(updates.toAsyncStream())
        } else {
            self._updates = nil
        }
    }

    func set(delegate: any StoreKit2PurchaseIntentListenerDelegate) async {
        self.delegate = delegate
    }

    func listenForPurchaseIntents() async {
        Logger.debug(Strings.storeKit.sk2_observing_purchase_intents)

        self.taskHandle?.cancel()
        self.taskHandle = Task(priority: .utility) { [weak self, updates = self.updates] in
            if let updates {
                for await purchaseIntent in updates {
                    guard let self = self else {
                        break
                    }

                    // Important that handling purchase intents doesn't block the thread
                    Task.detached {
                        await self.delegate?.storeKit2PurchaseIntentListener(self, purchaseIntent: purchaseIntent)
                    }
                }
            }
        }
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }
}

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct StorePurchaseIntent: Sendable, Equatable {

    #if compiler(>=5.10)
    init(purchaseIntent: PurchaseIntent?) {
        self.purchaseIntent = purchaseIntent
    }
    #else
    init() {}
    #endif

    // PurchaseIntents became available on macOS starting in macOS 14.4, which isn't available
    // until Xcode 15.3, which shipped with version 5.10 of the Swift compiler
    #if compiler(>=5.10)
    @available(iOS 16.4, macOS 14.4, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    let purchaseIntent: PurchaseIntent?
    #endif
}
