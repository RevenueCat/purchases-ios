//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StorefrontTests.swift
//
//  Created by Nacho Soto on 4/13/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
class StorefrontTests: StoreKitConfigTestCase {

    @MainActor
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCurrentStorefrontSK2() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let expectedStorefront = try await XCTAsyncUnwrap(await StoreKit.Storefront.current)
        let currentStorefront = try await XCTAsyncUnwrap(await Storefront.currentStorefront)

        expect(currentStorefront.identifier) == expectedStorefront.id
        expect(currentStorefront.countryCode) == expectedStorefront.countryCode

    }

    @MainActor
    func testCurrentStorefrontSK1() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        if #unavailable(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0) {
            let expectedStorefront = try XCTUnwrap(SKPaymentQueue.default().storefront)
            let currentStorefront = try await XCTAsyncUnwrap(await Storefront.currentStorefront)

            expect(currentStorefront.identifier) == expectedStorefront.identifier
            expect(currentStorefront.countryCode) == expectedStorefront.countryCode
        } else {
            throw XCTSkip("This test is for pre-iOS 15 APIs")
        }
    }

}
