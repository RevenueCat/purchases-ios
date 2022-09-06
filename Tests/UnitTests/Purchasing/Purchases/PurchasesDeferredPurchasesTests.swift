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

    private var storeKit1WrapperDelegate: StoreKit1WrapperDelegate!
    private var product: MockSK1Product!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()

        self.product = MockSK1Product(mockProductIdentifier: "mock_product")
        self.storeKit1WrapperDelegate = try XCTUnwrap(self.storeKit1Wrapper.delegate)
    }

    func testDeferBlockMakesPayment() throws {
        let payment = SKPayment(product: self.product)

        _ = self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper,
                                                           shouldAddStorePayment: payment,
                                                           for: self.product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        expect(self.storeKit1Wrapper.payment).to(beNil())

        let makeDeferredPurchase = try XCTUnwrap(purchasesDelegate.makeDeferredPurchase)

        makeDeferredPurchase { (_, _, _, _) in }

        expect(self.storeKit1Wrapper.payment) === payment
    }

    func testDeferBlockCallsCompletionBlockAfterPurchaseCompletes() throws {
        let payment = SKPayment(product: self.product)

        _ = self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                           shouldAddStorePayment: payment,
                                                           for: self.product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        expect(self.storeKit1Wrapper.payment).to(beNil())

        var completionCalled = false

        let makeDeferredPurchase = try XCTUnwrap(self.purchasesDelegate.makeDeferredPurchase)

        makeDeferredPurchase { (_, _, _, _) in
            completionCalled = true
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKit1Wrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.storeKit1Wrapper.payment) === payment
        expect(completionCalled).toEventually(beTrue())
    }

    func testCallsShouldAddPromoPaymentDelegateMethod() {
        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        _ = self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                           shouldAddStorePayment: payment,
                                                           for: self.product)

        expect(self.purchasesDelegate.promoProduct) == StoreProduct(sk1Product: self.product)
    }

    func testShouldAddStorePaymentReturnsFalseForNilProductIdentifier() {
        let payment = SKMutablePayment()
        payment.productIdentifier = ""

        let result = self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                                    shouldAddStorePayment: payment,
                                                                    for: self.product)

        expect(result) == false
        expect(self.purchasesDelegate.promoProduct).to(beNil())
    }

    func testPromoPaymentDelegateMethodMakesRightCalls() {
        let payment = SKPayment(product: self.product)

        _ = self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                           shouldAddStorePayment: payment,
                                                           for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedProductID) == self.product.productIdentifier
        expect(self.backend.postedPrice) == self.product.price as Decimal
    }

    func testPromoPaymentDelegateMethodCachesProduct() {
        let payment = SKPayment(product: product)

        _ = self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                           shouldAddStorePayment: payment,
                                                           for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == self.product
    }

}
