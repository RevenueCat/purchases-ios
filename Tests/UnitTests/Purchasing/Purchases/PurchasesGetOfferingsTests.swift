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

    func testFirstInitializationDoesntFetchOfferingsIfAppBackgrounded() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(0))
    }

    func testProductDataIsCachedForOfferings() throws {
        self.setupPurchases()

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        self.purchases.getOfferings { (newOfferings, _) in
            let storeProduct = newOfferings!["base"]!.monthly!.storeProduct
            let product = storeProduct.sk1Product!
            self.purchases.purchase(product: storeProduct) { (_, _, _, _) in }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price as Decimal))
            expect(self.backend.postedCurrencyCode).to(equal(product.priceLocale.currencyCode))

            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testInvalidateCustomerInfoCacheDoesntClearOfferingsCache() {
        self.setupPurchases()

        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0

        self.purchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0
    }

}
