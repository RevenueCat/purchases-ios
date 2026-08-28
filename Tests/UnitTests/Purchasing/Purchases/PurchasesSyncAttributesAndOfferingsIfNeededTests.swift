//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesSyncAttributesAndOfferingsIfNeededTests.swift
//
//  Created by Lauren Burdock on 2/26/24.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesSyncAttributesAndOfferingsTests: BasePurchasesTests {

    func testAttributesSyncedAndOfferingsFetched() throws {
        self.setupPurchases()

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                contents: .mockContents,
                                                                loadedFromDiskCache: false))
        )

        let result: Offerings? = waitUntilValue { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded(completion: { offerings, _ in
                completed(offerings)
            })
        }
        expect(result).toNot(beNil())
        expect(self.subscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 1
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }

    func testAttributesSyncedAndOfferingsFetchedAsync() async throws {
        self.setupPurchases()

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                contents: .mockContents,
                                                                loadedFromDiskCache: false))
        )

        let result: Offerings? = try await self.purchases.syncAttributesAndOfferingsIfNeeded()

        expect(result).toNot(beNil())
        expect(self.subscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 1
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }

    func testAttributeSyncErrorIsReturnedWithoutFetchingOfferings() throws {
        self.setupPurchases()

        let expectedError = ErrorUtils.networkError()
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                contents: .mockContents,
                                                                loadedFromDiskCache: false))
        )

        var receivedOfferings: Offerings?
        var receivedError: PublicError?
        waitUntil { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded { offerings, error in
                receivedOfferings = offerings
                receivedError = error
                completed()
            }
        }

        expect(receivedOfferings).to(beNil())
        expect(receivedError).to(matchError(expectedError))
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testAttributeSyncErrorIsThrownWithoutFetchingOfferingsAsync() async {
        self.setupPurchases()

        let expectedError = ErrorUtils.networkError()
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError

        do {
            _ = try await self.purchases.syncAttributesAndOfferingsIfNeeded()
            fail("Expected attribute sync error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testReservedAttributeSyncErrorDoesNotPreventFetchingOfferings() throws {
        self.setupPurchases()
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = self.attributeError(
            code: .invalidSubscriberAttributes,
            attributeErrors: ["$idfv": "IDFV cannot be modified."]
        )
        try self.stubOfferings()

        let result = self.syncAttributesAndOfferings()

        expect(result.offerings).toNot(beNil())
        expect(result.error).to(beNil())
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }

    func testCustomAttributeSyncErrorIsReturnedWithoutFetchingOfferings() {
        self.setupPurchases()
        let expectedError = self.attributeError(
            code: .invalidSubscriberAttributes,
            attributeErrors: ["favorite_color": "Value is too long."]
        )
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError

        let result = self.syncAttributesAndOfferings()

        expect(result.offerings).to(beNil())
        expect(result.error).to(matchError(expectedError.asPublicError))
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testMixedReservedAndCustomAttributeSyncErrorIsReturnedWithoutFetchingOfferings() {
        self.setupPurchases()
        let expectedError = self.attributeError(
            code: .invalidSubscriberAttributes,
            attributeErrors: [
                "$idfv": "IDFV cannot be modified.",
                "favorite_color": "Value is too long."
            ]
        )
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError

        let result = self.syncAttributesAndOfferings()

        expect(result.offerings).to(beNil())
        expect(result.error).to(matchError(expectedError.asPublicError))
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testReservedAttributeSyncErrorWithoutAttributeDetailsIsReturnedWithoutFetchingOfferings() {
        self.setupPurchases()
        let expectedError = self.attributeError(code: .invalidSubscriberAttributes, attributeErrors: [:])
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError

        let result = self.syncAttributesAndOfferings()

        expect(result.offerings).to(beNil())
        expect(result.error).to(matchError(expectedError.asPublicError))
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testInvalidAttributeBodyErrorForReservedAttributeIsReturnedWithoutFetchingOfferings() {
        self.setupPurchases()
        let expectedError = self.attributeError(
            code: .invalidSubscriberAttributesBody,
            attributeErrors: ["$idfv": "IDFV cannot be modified."]
        )
        self.subscriberAttributesManager.stubbedSyncAttributesForAllUsersError = expectedError

        let result = self.syncAttributesAndOfferings()

        expect(result.offerings).to(beNil())
        expect(result.error).to(matchError(expectedError.asPublicError))
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testRefreshesRemoteConfig() throws {
        self.systemInfo.stubbedRemoteConfigEnabled = true
        self.setupPurchases()
        try self.stubOfferings()

        let refreshCountBeforeSync = self.mockRemoteConfigManager.invokedRefreshRemoteConfigCount

        let result: Offerings? = waitUntilValue { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded(completion: { offerings, _ in
                completed(offerings)
            })
        }

        expect(result).toNot(beNil())
        expect(self.mockRemoteConfigManager.invokedRefreshRemoteConfigCount) == refreshCountBeforeSync + 1
        expect(self.mockRemoteConfigManager.invokedRefreshRemoteConfigParametersList.last?.fetchContext) == .read
    }

    func testDoesNotRefreshRemoteConfigWhenRateLimitIsReached() throws {
        self.systemInfo.stubbedRemoteConfigEnabled = true
        self.setupPurchases()
        try self.stubOfferings()

        for _ in 0..<Self.rateLimitMaxCalls {
            waitUntil { completed in
                self.purchases.syncAttributesAndOfferingsIfNeeded(completion: { _, _ in
                    completed()
                })
            }
        }

        let refreshCountBeforeRateLimitedSync = self.mockRemoteConfigManager.invokedRefreshRemoteConfigCount
        expect(refreshCountBeforeRateLimitedSync) >= Self.rateLimitMaxCalls

        waitUntil { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded(completion: { _, _ in
                completed()
            })
        }

        expect(self.subscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == Self.rateLimitMaxCalls
        expect(self.mockRemoteConfigManager.invokedRefreshRemoteConfigCount) == refreshCountBeforeRateLimitedSync
    }

    private static let rateLimitMaxCalls = 5

    private func stubOfferings() throws {
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                contents: .mockContents,
                                                                loadedFromDiskCache: false))
        )
    }

    private func syncAttributesAndOfferings() -> (offerings: Offerings?, error: PublicError?) {
        var result: (offerings: Offerings?, error: PublicError?) = (nil, nil)

        waitUntil { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded { offerings, error in
                result = (offerings, error)
                completed()
            }
        }

        return result
    }

    private func attributeError(
        code: BackendErrorCode,
        attributeErrors: [String: String]
    ) -> PurchasesError {
        return ErrorResponse(
            code: code,
            originalCode: code.rawValue,
            message: "Invalid attributes",
            attributeErrors: attributeErrors
        ).asBackendError(with: .invalidRequest)
    }
}
