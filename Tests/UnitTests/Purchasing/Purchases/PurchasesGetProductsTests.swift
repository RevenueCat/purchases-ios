//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesGetProductsTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesGetProductsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testDoesntFetchProductDataIfEmptyList() {
        self.mockProductsManager.resetMock()

        waitUntil { completed in
            self.purchases.getProducts([]) { _ in
                completed()
            }
        }

        expect(self.mockProductsManager.invokedProducts) == false
    }

    func testIsAbleToFetchProducts() {
        let productIdentifiers = ["com.product.id1", "com.product.id2"]

        let products = waitUntilValue { completed in
            self.purchases.getProducts(productIdentifiers, completion: completed)
        }

        expect(products).to(haveCount(productIdentifiers.count))
    }

    func testGetEligibility() {
        self.purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: ["product 1"]) { (_) in }

        expect(
            self.trialOrIntroPriceEligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore
        ) == true
    }

}

class PurchasesGetProductsBackgroundTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
    }

    func testFetchesProductDataIfNotCached() throws {
        let sk1Product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let product = StoreProduct(sk1Product: sk1Product)

        let transaction = MockTransaction()
        self.storeKit1Wrapper.payment = SKPayment(product: sk1Product)
        transaction.mockPayment = self.storeKit1Wrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedProductsParameters).toEventually(contain([product.productIdentifier]))

        expect(self.backend.postedProductID).toNot(beNil())
        expect(self.backend.postedPrice).toNot(beNil())
        expect(self.backend.postedCurrencyCode).toNot(beNil())
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expect(self.backend.postedIntroPrice).toNot(beNil())
        }
    }

}
