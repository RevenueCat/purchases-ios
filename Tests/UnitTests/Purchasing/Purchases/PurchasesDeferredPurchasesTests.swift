//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDeferredPurchasesTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchaseDeferredPurchasesTests: BasePurchasesTests {

    private var storeKitWrapperDelegate: StoreKitWrapperDelegate!
    private var product: MockSK1Product!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()

        self.product = MockSK1Product(mockProductIdentifier: "mock_product")
        self.storeKitWrapperDelegate = try XCTUnwrap(self.storeKitWrapper.delegate)
    }

    func testDeferBlockMakesPayment() throws {
        let payment = SKPayment(product: self.product)

        _ = self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper,
                                                         shouldAddStorePayment: payment,
                                                         for: self.product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        expect(self.storeKitWrapper.payment).to(beNil())

        let makeDeferredPurchase = try XCTUnwrap(purchasesDelegate.makeDeferredPurchase)

        makeDeferredPurchase { (_, _, _, _) in }

        expect(self.storeKitWrapper.payment) === payment
    }

    func testDeferBlockCallsCompletionBlockAfterPurchaseCompletes() throws {
        let payment = SKPayment(product: self.product)

        _ = self.storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                         shouldAddStorePayment: payment,
                                                         for: self.product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        expect(self.storeKitWrapper.payment).to(beNil())

        var completionCalled = false

        let makeDeferredPurchase = try XCTUnwrap(self.purchasesDelegate.makeDeferredPurchase)

        makeDeferredPurchase { (_, _, _, _) in
            completionCalled = true
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.storeKitWrapper.payment) === payment
        expect(completionCalled).toEventually(beTrue())
    }

    func testCallsShouldAddPromoPaymentDelegateMethod() {
        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        _ = self.storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                         shouldAddStorePayment: payment,
                                                         for: self.product)

        expect(self.purchasesDelegate.promoProduct) == StoreProduct(sk1Product: self.product)
    }

    func testShouldAddStorePaymentReturnsFalseForNilProductIdentifier() {
        let payment = SKMutablePayment()
        payment.productIdentifier = ""

        let result = self.storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                                  shouldAddStorePayment: payment,
                                                                  for: self.product)

        expect(result) == false
        expect(self.purchasesDelegate.promoProduct).to(beNil())
    }

    func testPromoPaymentDelegateMethodMakesRightCalls() {
        let payment = SKPayment(product: self.product)

        _ = self.storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                         shouldAddStorePayment: payment,
                                                         for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedProductID) == self.product.productIdentifier
        expect(self.backend.postedPrice) == self.product.price as Decimal
    }

    func testPromoPaymentDelegateMethodCachesProduct() {
        let payment = SKPayment(product: product)

        _ = self.storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                         shouldAddStorePayment: payment,
                                                         for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        self.storeKitWrapperDelegate.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == self.product
    }

}
