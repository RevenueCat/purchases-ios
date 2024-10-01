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

    private var storeKit1WrapperDelegate: StoreKit1WrapperDelegate {
        get throws {
            return try XCTUnwrap(self.storeKit1Wrapper.delegate)
        }
    }

    private var product: MockSK1Product!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()

        self.product = MockSK1Product(mockProductIdentifier: "mock_product")
    }

    func testDeferBlockMakesPayment() throws {
        let payment = SKPayment(product: self.product)

        _ = try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper,
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

        _ = try self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: self.product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        expect(self.storeKit1Wrapper.payment).to(beNil())

        let completionCalled: Atomic<Bool> = false

        let makeDeferredPurchase = try XCTUnwrap(self.purchasesDelegate.makeDeferredPurchase)

        makeDeferredPurchase { (_, _, _, _) in
            completionCalled.value = true
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKit1Wrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.storeKit1Wrapper.payment) === payment
        expect(completionCalled.value).toEventually(beTrue())
    }

    func testCallsShouldAddPromoPaymentDelegateMethod() throws {
        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        _ = try self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: self.product)

        expect(self.purchasesDelegate.promoProduct) == StoreProduct(sk1Product: self.product)
    }

    func testShouldAddStorePaymentReturnsFalseForNilProductIdentifier() throws {
        let payment = SKMutablePayment()
        payment.productIdentifier = ""

        let result = try self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                                        shouldAddStorePayment: payment,
                                                                        for: self.product)

        expect(result) == false
        expect(self.purchasesDelegate.promoProduct).to(beNil())
    }

    func testPromoPaymentDelegateMethodMakesRightCalls() throws {
        let payment = SKPayment(product: self.product)

        _ = try self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedProductID) == self.product.productIdentifier
        expect(self.backend.postedPrice) == self.product.price as Decimal
    }

    func testPromoPaymentDelegateMethodCachesProduct() throws {
        let payment = SKPayment(product: product)

        _ = try self.storeKit1WrapperDelegate.storeKit1Wrapper(storeKit1Wrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        try self.storeKit1WrapperDelegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter.map(StoreProduct.from(product:)))
        == StoreProduct(sk1Product: self.product)
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchaseDeferredPurchasesSK2Tests: BasePurchasesTests {

    private var paymentQueueWrapperDelegate: PaymentQueueWrapperDelegate {
        get throws {
            return try XCTUnwrap(self.mockPaymentQueueWrapper.delegate)
        }
    }
    private var product: MockSK1Product!

    override var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.setupPurchases()

        self.product = MockSK1Product(mockProductIdentifier: "mock_product")
    }

    func testDeferBlockMakesPayment() throws {
        let payment = SKPayment(product: self.product)

        _ = try self.paymentQueueWrapperDelegate.paymentQueueWrapper(
            self.mockPaymentQueueWrapper,
            shouldAddStorePayment: payment,
            for: self.product
        )

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())

        expect(self.purchasesDelegate.promoProduct) == StoreProduct(sk1Product: self.product)
        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
    }

}
