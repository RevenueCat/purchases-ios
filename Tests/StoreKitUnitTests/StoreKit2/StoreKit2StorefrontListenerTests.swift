//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2StorefrontListenerTests.swift
//
//  Created by Juanpe Catalán on 9/5/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListenerTests: TestCase {

    private var delegate: MockStoreKit2StorefrontListenerDelegate! = nil
    private var listener: StoreKit2StorefrontListener! = nil

    private static let storefronts = [
        MockStorefront(countryCode: "ESP"),
        MockStorefront(countryCode: "USA")
    ]
        .map(Storefront.from(storefront:))

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.delegate = .init()
        self.listener = .init(delegate: self.delegate,
                              updates: MockAsyncSequence(with: Self.storefronts as [StorefrontType]))
    }

    func testStopsListeningToChangesWhenListenerIsReleased() throws {
        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener.listenForStorefrontChanges()
        handle = self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    func testNotifiesDelegate() throws {
        self.listener.listenForStorefrontChanges()

        expect(self.delegate.invokedStorefrontDidUpdateStorefronts.value)
            .toEventually(equal(Self.storefronts))
    }

    func testStopsPreviousTaskWhenStartListeningChangesMoreThanOneTime() throws {
        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener.listenForStorefrontChanges()
        handle = self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener.listenForStorefrontChanges()
        expect(handle?.isCancelled) == true
    }

}

private final class MockStoreKit2StorefrontListenerDelegate: StoreKit2StorefrontListenerDelegate {

    let invokedStorefrontDidUpdateStorefronts: Atomic<[RevenueCat.Storefront]> = .init([])

    func storefrontDidUpdate(with storefront: StorefrontType) {
        self.invokedStorefrontDidUpdateStorefronts.value.append(.from(storefront: storefront))
    }

}
