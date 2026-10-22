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

class CachingTrialOrIntroPriceEligibilityCheckerTests: TestCase {

    private typealias Result = [String: IntroEligibility]

    private var mockChecker: MockTrialOrIntroPriceEligibilityChecker!
    private var caching: CachingTrialOrIntroPriceEligibilityChecker!

    override func setUpWithError() throws {
        try super.setUpWithError()

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

    func testCallsCompletionOnMainThread() async {
        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]
        self.mockChecker.stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = expected
        let completionCalled = self.expectation(description: "Completion called")

        self.caching.checkEligibility(productIdentifiers: [Self.productID1]) { result in
            expect(Thread.isMainThread).to(beTrue())
            expect(result) == expected
            completionCalled.fulfill()
        }

        await self.fulfillment(of: [completionCalled], timeout: 1)
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
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList) == [
            productIDs,
            [Self.productID2]
        ]
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
        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList) == [
            cachedProductIDs,
            [Self.productID3]
        ]

        let cachedResult = await self.caching.checkEligibility(productIdentifiers: productIDs)
        expect(cachedResult) == allEligibilities

        expect(self.mockChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 2
    }

    func testIdenticalRequestsShareInFlightCheck() async {
        let checker = DelayedTrialOrIntroPriceEligibilityChecker()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let productIDs: Set<String> = [Self.productID1, Self.productID2]

        let firstRequest = Task {
            await caching.checkEligibility(productIdentifiers: productIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(1))

        let secondRequest = Task {
            await caching.checkEligibility(productIdentifiers: productIDs)
        }

        await expect(checker.invocations.count).toAlways(equal(1))

        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .ineligible)
        ]
        checker.complete(productIdentifiers: productIDs, with: expected)

        let receivedFirstResult = await firstRequest.value
        let receivedSecondResult = await secondRequest.value

        expect(checker.invocations) == [productIDs]
        expect(receivedFirstResult) == expected
        expect(receivedSecondResult) == expected
        self.logger.verifyMessageWasLogged(
            Strings.eligibility.waiting_for_intro_eligibility(productIDs), level: .debug, expectedCount: 1
        )
    }

    func testRequestSharesInFlightCheckContainingAllItsProducts() async {
        let checker = DelayedTrialOrIntroPriceEligibilityChecker()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let firstProductIDs: Set<String> = [Self.productID1, Self.productID2]
        let secondProductIDs: Set<String> = [Self.productID1]

        let firstRequest = Task {
            await caching.checkEligibility(productIdentifiers: firstProductIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(1))

        let secondRequest = Task {
            await caching.checkEligibility(productIdentifiers: secondProductIDs)
        }

        await expect(checker.invocations.count).toAlways(equal(1))

        let expected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .ineligible)
        ]
        checker.complete(productIdentifiers: firstProductIDs, with: expected)

        let receivedFirstResult = await firstRequest.value
        let receivedSecondResult = await secondRequest.value

        expect(checker.invocations) == [firstProductIDs]
        expect(receivedFirstResult) == expected
        expect(receivedSecondResult) == expected.filter { secondProductIDs.contains($0.key) }
    }

    func testRequestDoesNotShareInFlightCheckMissingSomeOfItsProducts() async {
        let checker = DelayedTrialOrIntroPriceEligibilityChecker()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let firstProductIDs: Set<String> = [Self.productID1]
        let secondProductIDs: Set<String> = [Self.productID1, Self.productID2]

        let firstRequest = Task {
            await caching.checkEligibility(productIdentifiers: firstProductIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(1))

        let secondRequest = Task {
            await caching.checkEligibility(productIdentifiers: secondProductIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(2))

        let firstExpected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]
        let secondExpected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible),
            Self.productID2: .init(eligibilityStatus: .ineligible)
        ]
        checker.complete(productIdentifiers: firstProductIDs, with: firstExpected)
        checker.complete(productIdentifiers: secondProductIDs, with: secondExpected)

        let receivedFirstResult = await firstRequest.value
        let receivedSecondResult = await secondRequest.value

        expect(checker.invocations) == [firstProductIDs, secondProductIDs]
        expect(receivedFirstResult) == firstExpected
        expect(receivedSecondResult) == secondExpected
    }

    func testClearCacheDoesNotShareOrCacheInFlightRequestFromPreviousGeneration() async {
        let checker = DelayedTrialOrIntroPriceEligibilityChecker()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let productIDs: Set<String> = [Self.productID1]

        let firstRequest = Task {
            await caching.checkEligibility(productIdentifiers: productIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(1))
        caching.clearCache()

        let secondRequest = Task {
            await caching.checkEligibility(productIdentifiers: productIDs)
        }

        await expect(checker.invocations.count).toEventually(equal(2))

        let firstExpected: Result = [
            Self.productID1: .init(eligibilityStatus: .eligible)
        ]
        let secondExpected: Result = [
            Self.productID1: .init(eligibilityStatus: .ineligible)
        ]
        checker.complete(productIdentifiers: productIDs, with: firstExpected)
        checker.complete(productIdentifiers: productIDs, with: secondExpected)

        let receivedFirstResult = await firstRequest.value
        let receivedSecondResult = await secondRequest.value
        let cachedResult = await caching.checkEligibility(productIdentifiers: productIDs)

        expect(checker.invocations) == [productIDs, productIDs]
        expect(receivedFirstResult) == firstExpected
        expect(receivedSecondResult) == secondExpected
        expect(cachedResult) == secondExpected
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

private final class DelayedTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType,
                                                                @unchecked Sendable {

    private struct State {
        var invocations: [Set<String>] = []
        var completions: [Set<String>: [ReceiveIntroEligibilityBlock]] = [:]
    }

    private let state = Atomic(State())

    var invocations: [Set<String>] {
        return self.state.value.invocations
    }

    func checkEligibility(
        productIdentifiers: Set<String>,
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        self.state.modify {
            $0.invocations.append(productIdentifiers)
            $0.completions[productIdentifiers, default: []].append(completion)
        }
    }

    func complete(
        productIdentifiers: Set<String>,
        with result: [String: IntroEligibility]
    ) {
        let completion: ReceiveIntroEligibilityBlock? = self.state.modify { state in
            guard var completions = state.completions[productIdentifiers], !completions.isEmpty else {
                return nil
            }

            let completion = completions.removeFirst()
            state.completions[productIdentifiers] = completions.isEmpty ? nil : completions
            return completion
        }
        completion?(result)
    }

}

// MARK: -

private extension CachingTrialOrIntroPriceEligibilityCheckerTests {

    static let productID1 = "com.revenuecat.product_1"
    static let productID2 = "com.revenuecat.product_2"
    static let productID3 = "com.revenuecat.product_3"

}

private extension TrialOrIntroPriceEligibilityCheckerType {

    func checkEligibility(productIdentifiers: Set<String>) async -> [String: IntroEligibility] {
        return await Async.call { completion in
            self.checkEligibility(productIdentifiers: productIdentifiers) { result in
                completion(result)
            }
        }
    }

}
