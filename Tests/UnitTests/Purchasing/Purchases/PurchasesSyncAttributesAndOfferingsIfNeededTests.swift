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
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
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
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        let result: Offerings? = try await self.purchases.syncAttributesAndOfferingsIfNeeded()

        expect(result).toNot(beNil())
        expect(self.subscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 1
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }
}
