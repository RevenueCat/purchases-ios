//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesGetOfferingsTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesGetOfferingsTests: BasePurchasesTests {

    func testFirstInitializationGetsOfferingsIfAppActive() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationGetsOfferingsIfAppActiveInCustomEntitlementComputation() {
        self.systemInfo = .init(finishTransactions: true, customEntitlementsComputation: true)
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationGetsOfflineEntitlementsIfAppActive() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfflineEntitlementsManager.invokedUpdateProductsEntitlementsCacheIfStaleCount)
            .toEventually(equal(1))
    }

    func testFirstInitializationDoesntFetchOfferingsOrOfflineEntitlementsIfAppBackgrounded() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCache) == false
        expect(self.mockOfflineEntitlementsManager.invokedUpdateProductsEntitlementsCacheIfStale) == false
    }

    func testProductDataIsCachedForOfferings() throws {
        self.setupPurchases()

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        let result: SK1Product? = waitUntilValue { completed in
            self.purchases.getOfferings { (newOfferings, _) in
                let storeProduct = newOfferings!["base"]!.monthly!.storeProduct

                self.purchases.purchase(product: storeProduct) { (_, _, _, _) in }

                let transaction = MockTransaction()
                transaction.mockPayment = self.storeKit1Wrapper.payment!

                transaction.mockState = SKPaymentTransactionState.purchasing
                self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

                self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)

                transaction.mockState = SKPaymentTransactionState.purchased
                self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

                completed(storeProduct.sk1Product)
            }
        }

        let product = try XCTUnwrap(result)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedReceiptData).toNot(beNil())

        expect(self.backend.postedProductID) == product.productIdentifier
        expect(self.backend.postedPrice) == product.price as Decimal
        expect(self.backend.postedCurrencyCode) == product.priceLocale.currencyCode

        expect(self.storeKit1Wrapper.finishCalled).toEventually(beTrue())
    }

    func testInvalidateCustomerInfoCacheDoesntClearOfferingsCache() {
        self.setupPurchases()

        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0

        self.purchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0
    }

    func testWarmsUpPaywallsCache() throws {
        let bundle = Bundle(for: Self.self)
        let offeringsURL = try XCTUnwrap(bundle.url(forResource: "Offerings",
                                                    withExtension: "json",
                                                    subdirectory: "Fixtures"))
        let offeringsResponse = try OfferingsResponse.create(with: XCTUnwrap(Data(contentsOf: offeringsURL)))

        let offering = Offering(
            identifier: "offering",
            serverDescription: "",
            paywall: nil,
            availablePackages: []
        )
        let offerings = Offerings(
            offerings: [
                offering.identifier: offering
            ],
            currentOfferingID: offering.identifier,
            response: offeringsResponse
        )

        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.mockOfferingsManager.stubbedUpdateOfferingsCompletionResult = .success(offerings)

        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))

        expect(self.paywallCache.invokedWarmUpEligibilityCache) == true
        expect(self.paywallCache.invokedWarmUpEligibilityCacheOfferings) == offerings

        expect(self.paywallCache.invokedWarmUpPaywallImagesCache) == true
        expect(self.paywallCache.invokedWarmUpPaywallImagesCacheOfferings) == offerings
    }

}
