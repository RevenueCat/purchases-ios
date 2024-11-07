//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesWinBackOfferTests.swift
//
//  Created by Will Taylor on 10/31/24.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@MainActor
class PurchasesWinBackOfferTests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    // Win-backs are available in Xcode 16.0+, which ships with the 6.0 version
    // of the Swift compiler
    #if compiler(>=6.0)
    // MARK: - Success Cases
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibileWinBackOffersAsyncForwardsSuccess() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "abc123"))
        self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersResult = .success

        let eligibleWinBackOffers = try await self.purchases.eligibleWinBackOffers(forProduct: product)
        expect(eligibleWinBackOffers).to(equal([]))
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCalled).to(beTrue())
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCallCount).to(equal(1))
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersProduct).to(equal(product))
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibileWinBackOffersCallbackForwardsSuccess() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "abc123"))
        self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersResult = .success

        let expectation = self.expectation(description: "Wait for eligibleWinBackOffers callback")
        self.purchases.eligibleWinBackOffers(forProduct: product) { callResult in

            expect(callResult.value).to(equal([]))
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3)

        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCalled).to(beTrue())
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCallCount).to(equal(1))
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersProduct).to(equal(product))
    }

    // MARK: - Error Cases
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibileWinBackOffersAsyncForwardsErrors() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "abc123"))
        self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersResult = .error

        var error: Error?
        do {
            _ = try await self.purchases.eligibleWinBackOffers(forProduct: product)
        } catch let thrownError {
            error = thrownError
        }

        expect(error).to(matchError(ErrorCode.featureNotSupportedWithStoreKit1))
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibileWinBackOffersCallbackForwardsErrors() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "abc123"))
        self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersResult = .error

        let expectation = self.expectation(description: "Wait for eligibleWinBackOffers callback")
        self.purchases.eligibleWinBackOffers(forProduct: product) { callResult in
            expect(callResult.error).to(matchError(ErrorCode.featureNotSupportedWithStoreKit1))
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3)
    }

    // MARK: - Misc Tests
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibileWinBackOffersCallbackCallsCallbackOnMainThread() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "abc123"))

        let expectation = self.expectation(description: "Wait for eligibleWinBackOffers callback")
        self.purchases.eligibleWinBackOffers(forProduct: product) { _ in
            expect(Thread.isMainThread).to(beTrue())
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3)
    }
    #endif
}
