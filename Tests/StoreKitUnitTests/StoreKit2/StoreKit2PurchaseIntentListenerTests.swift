//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2PurchaseIntentListenerTests.swift
//
//  Created by Will Taylor on 10/10/24.

import Nimble
@testable import RevenueCat
import StoreKit
import StoreKitTest
import XCTest

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
class StoreKit2PurchaseIntentListenerBaseTests: StoreKitConfigTestCase {

    fileprivate var listener: StoreKit2PurchaseIntentListener! = nil
    fileprivate var delegate: MockStoreKit2PurchaseIntentListenerDelegate! = nil

    fileprivate var updatesContinuation: AsyncStream<StorePurchaseIntent>.Continuation?

    var updates: AsyncStream<StorePurchaseIntent> {
        get async throws {
            return AsyncStream { continuation in
                self.updatesContinuation = continuation
            }
        }
    }

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        // Unfinished transactions before beginning the test might lead to false positives / negatives
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            await self.verifyNoUnfinishedTransactions()
        }

        self.delegate = .init()
        self.listener = StoreKit2PurchaseIntentListener(delegate: self.delegate, updates: try await self.updates)
    }

}

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
class StoreKit2PurchaseIntentListenerTests: StoreKit2PurchaseIntentListenerBaseTests {

    func testStopsListeningToTransactions() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        handle = await self.listener.taskHandle
        expect(handle).to(beNil())

        await self.listener.listenForPurchaseIntents()
        handle = await self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    func testSendsPurchaseIntentsToDelegate() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let delegate = MockStoreKit2PurchaseIntentListenerDelegate()
        await self.listener.set(delegate: delegate)
        await self.listener.listenForPurchaseIntents()

        expect(delegate.storeKit2PurchaseIntentListenerInvokeCount).to(equal(0))
        expect(delegate.storeKit2PurchaseIntentListenerInvoked).to(beFalse())
        expect(delegate.storeKit2PurchaseIntentListenerPurchaseIntent).to(beNil())

        #if compiler(>=5.10)
        let purchaseIntent = StorePurchaseIntent(purchaseIntent: nil)
        #else
        let purchaseIntent = StorePurchaseIntent()
        #endif

        self.updatesContinuation?.yield(purchaseIntent)

        // Wait for the delegate to be invoked and the StorePurchaseIntent to be received
        try await asyncWait(
            description: "Delegate should be notified of new purchase intent",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100)
        ) {
            delegate.storeKit2PurchaseIntentListenerInvoked == true
            && delegate.storeKit2PurchaseIntentListenerInvokeCount == 1
            && delegate.storeKit2PurchaseIntentListenerPurchaseIntent == purchaseIntent
        }
    }
}
