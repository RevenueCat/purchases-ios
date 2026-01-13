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

    private static let userDefaultsSuiteName = "StoreKit2StorefrontListenerTests"

    private var delegate: MockStoreKit2StorefrontListenerDelegate! = nil
    private var listener: StoreKit2StorefrontListener! = nil
    private var userDefaults: UserDefaults! = nil

    private static let defaultStorefronts = [
        MockStorefront(countryCode: "ESP"),
        MockStorefront(countryCode: "USA")
    ]
    private var storefronts: [MockStorefront]?

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        // Create isolated UserDefaults for each test
        self.userDefaults = UserDefaults(suiteName: Self.userDefaultsSuiteName)
        self.userDefaults.removePersistentDomain(forName: Self.userDefaultsSuiteName)
        self.userDefaults.synchronize()

        self.delegate = .init()
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        self.userDefaults.removePersistentDomain(forName: Self.userDefaultsSuiteName)
        self.userDefaults.synchronize()

        super.tearDown()
    }

    func testStopsListeningToChangesWhenListenerIsReleased() throws {
        self.setupStorefrontListener()

        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener.listenForStorefrontChanges()
        handle = self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil

        expect(handle?.isCancelled).toEventually(beTrue())
    }

    func testNotifiesDelegate() throws {
        self.setupStorefrontListener()

        self.listener.listenForStorefrontChanges()

        expect(self.delegate.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(equal(Self.defaultStorefronts.map(Storefront.from(storefront:))))
    }

    func testStopsPreviousTaskWhenStartListeningChangesMoreThanOneTime() throws {
        self.setupStorefrontListener()

        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener.listenForStorefrontChanges()
        handle = self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener.listenForStorefrontChanges()
        expect(handle?.isCancelled) == true
    }

    func testReceivesStorefrontUpdateThroughDelegate() throws {
        self.storefronts = [
            MockStorefront(countryCode: "USA")
        ]

        self.setupStorefrontListener()

        self.listener.listenForStorefrontChanges()

        expect(self.delegate.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(1))
        expect(self.delegate.invokedStorefrontIdentifierDidChangeStorefronts.value.first?.countryCode) == "USA"
    }

    /// The same storefront should not be emitted more than once
    func testDeduplicatesStorefrontUpdates() throws {
        self.storefronts = [
            MockStorefront(countryCode: "USA"),
            MockStorefront(countryCode: "USA")
        ]

        self.setupStorefrontListener()

        self.listener.listenForStorefrontChanges()

        // Verify the delegate receives only one update (the first one), not the duplicate
        expect(self.delegate.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(1))
        expect(self.delegate.invokedStorefrontIdentifierDidChangeStorefronts.value.first?.countryCode) == "USA"
    }

    /// Tests that a second instance of the listener (a new instance when relaunching the app)
    /// does not emit if the storefront hasn't changed since the last instance
    func testDeduplicatesStorefrontUpdatesAcrossInstancesWithoutChange() throws {
        let storefront = MockStorefront(countryCode: "USA")

        let testSuiteName = "test.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
        userDefaults.synchronize()

        let testDelegate1 = MockStoreKit2StorefrontListenerDelegate()
        let testListener1 = StoreKit2StorefrontListener(
            delegate: testDelegate1,
            updates: MockAsyncSequence(with: [storefront] as [StorefrontType]),
            userDefaults: userDefaults
        )

        testListener1.listenForStorefrontChanges()

        expect(testDelegate1.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(1))
        expect(testDelegate1.invokedStorefrontIdentifierDidChangeStorefronts.value.first?.countryCode) == "USA"

        let testDelegate2 = MockStoreKit2StorefrontListenerDelegate()
        let testListener2 = StoreKit2StorefrontListener(
            delegate: testDelegate2,
            updates: MockAsyncSequence(with: [storefront] as [StorefrontType]),
            userDefaults: userDefaults
        )

        testListener2.listenForStorefrontChanges()

        expect(testDelegate2.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(0))
        expect(testDelegate2.invokedStorefrontIdentifierDidChangeStorefronts.value.first).to(beNil())
    }

    /// Tests that a second instance of the listener (a new instance when relaunching the app)
    /// does emit when the storefront changed between instances
    func testDeduplicatesStorefrontUpdatesAcrossInstancesWithChange() throws {

        let testSuiteName = "test.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
        userDefaults.synchronize()

        let storefront1 = MockStorefront(countryCode: "USA")
        let testDelegate1 = MockStoreKit2StorefrontListenerDelegate()
        let testListener1 = StoreKit2StorefrontListener(
            delegate: testDelegate1,
            updates: MockAsyncSequence(with: [storefront1] as [StorefrontType]),
            userDefaults: userDefaults
        )

        testListener1.listenForStorefrontChanges()

        expect(testDelegate1.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(1))
        expect(testDelegate1.invokedStorefrontIdentifierDidChangeStorefronts.value.first?.countryCode) == "USA"

        let storefront2 = MockStorefront(countryCode: "NLD")
        let testDelegate2 = MockStoreKit2StorefrontListenerDelegate()
        let testListener2 = StoreKit2StorefrontListener(
            delegate: testDelegate2,
            updates: MockAsyncSequence(with: [storefront2] as [StorefrontType]),
            userDefaults: userDefaults
        )

        testListener2.listenForStorefrontChanges()

        expect(testDelegate2.invokedStorefrontIdentifierDidChangeStorefronts.value)
            .toEventually(haveCount(1))
        expect(testDelegate2.invokedStorefrontIdentifierDidChangeStorefronts.value.first?.countryCode) == "NLD"
    }

    private func setupStorefrontListener() {
        let storefronts = (storefronts ?? Self.defaultStorefronts).map(Storefront.from(storefront:))
        self.listener = .init(
            delegate: self.delegate,
            updates: MockAsyncSequence(
                with: storefronts as [StorefrontType]
            ),
            userDefaults: self.userDefaults
        )
    }
}

private final class MockStoreKit2StorefrontListenerDelegate: StoreKit2StorefrontListenerDelegate {

    let invokedStorefrontIdentifierDidChangeStorefronts: Atomic<[RevenueCat.Storefront]> = .init([])

    func storefrontIdentifierDidChange(with storefront: StorefrontType) {
        self.invokedStorefrontIdentifierDidChangeStorefronts.value.append(.from(storefront: storefront))
    }

}
