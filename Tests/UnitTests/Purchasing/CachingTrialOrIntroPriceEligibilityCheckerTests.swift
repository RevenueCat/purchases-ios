//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CachingTrialOrIntroPriceEligibilityCheckerTests.swift
//
//  Created by Nacho Soto on 10/27/22.

import Nimble
@testable import RevenueCat
import XCTest

// swiftlint:disable type_name

@available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
@MainActor
class CachingTrialOrIntroPriceEligibilityCheckerTests: TestCase {

    private typealias Result = [String: IntroEligibility]

    private var mockChecker: MockTrialOrIntroPriceEligibilityChecker!
    private var caching: CachingTrialOrIntroPriceEligibilityChecker!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.mockChecker = .init()
        self.caching = .init(checker: self.mockChecker)
    }

    func testChecksWithoutCache() async {
        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected

        let result = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])

        expect(result) == expected
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters) == [Self.productID1]
    }

    func testCachesResultForOneProduct() async {
        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected

        _ = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])
        let result = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])

        expect(result) == expected

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters) == [Self.productID1]
    }

    func testRetriesIfFailed() async {
        let unknownResult: Result = [
            Self.productID1: .init(eligibilityStatus: .unknown)
        ]
        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult
        = unknownResult

        let result1 = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])
        expect(result1) == unknownResult

        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .noIntroOfferExists)
        ]
        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected

        let result2 = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])
        expect(result2) == expected

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList) == [
            [Self.productID1],
            [Self.productID1]
        ]
    }

    func testCachesResultForMultipleProducts() async {
        let productIDs: Set<String> = [
            Self.productID1,
            Self.productID2
        ]

        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .noIntroOfferExists)
        ]

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected

        _ = await self.caching.checkEligibility(productIdentifiers: productIDs)
        let result = await self.caching.checkEligibility(productIdentifiers: productIDs)

        expect(result) == expected

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters) == productIDs
    }

    func testOnlyCachesEligibilitiesThatDidNotFail() async {
        let productIDs: Set<String> = [
            Self.productID1,
            Self.productID2
        ]

        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .unknown)
        ]

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected

        _ = await self.caching.checkEligibility(productIdentifiers: productIDs)
        let result = await self.caching.checkEligibility(productIdentifiers: productIDs)

        expect(result) == expected

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList)
            .to(contain([
                [Self.productID1, Self.productID2],
                [Self.productID2]
            ]))
    }

    func testFetchesOnlyMissingProductsFromCache() async {
        let cachedProductIDs: Set<String> = [
            Self.productID1,
            Self.productID2
        ]
        let productIDs: Set<String> = [
            Self.productID1,
            Self.productID2,
            Self.productID3
        ]

        let cachedEligibility: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .noIntroOfferExists)
        ]
        let updatedEligibility: Result = [
            Self.productID3: .init(eligibilityStatus: .ineligible)
        ]
        let allEligibilities = cachedEligibility + updatedEligibility

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult
        = cachedEligibility

        _ = await self.caching.checkEligibility(productIdentifiers: cachedProductIDs)

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult
        = updatedEligibility

        let result = await self.caching.checkEligibility(productIdentifiers: productIDs)

        expect(result) == allEligibilities

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList)
            .to(contain([
                Set(cachedProductIDs),
                [Self.productID3]
            ]))

        let cachedResult = await self.caching.checkEligibility(productIdentifiers: productIDs)
        expect(cachedResult) == allEligibilities

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
    }

    func testClearCache() async {
        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]

        // 1. Cache result

        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected
        _ = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])

        // 2. Clear cache

        self.caching.clearCache()

        // 3. Request again

        let result = await self.caching.checkEligibility(productIdentifiers: [Self.productID1])
        expect(result) == expected

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList) == [
            [Self.productID1],
            [Self.productID1]
        ]
    }

}

// MARK: -

@available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
private extension CachingTrialOrIntroPriceEligibilityCheckerTests {

    static let productID1 = "com.revenuecat.product_1"
    static let productID2 = "com.revenuecat.product_2"
    static let productID3 = "com.revenuecat.product_3"

}

@available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
private extension TrialOrIntroPriceEligibilityCheckerType {

    func checkEligibility(productIdentifiers: Set<String>) async -> [String: IntroEligibility] {
        return await Async.call { completion in
            self.checkEligibility(productIdentifiers: productIdentifiers) { result in
                completion(result)
            }
        }
    }

}
