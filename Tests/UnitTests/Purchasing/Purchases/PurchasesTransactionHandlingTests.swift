//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesTransactionHandlingTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesTransactionHandlingTests: BasePurchasesTests {

    private var product: MockSK1Product!
    private var customerInfoBeforePurchase: CustomerInfo!
    private var customerInfoAfterPurchase: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.product = MockSK1Product(mockProductIdentifier: "product")

        self.customerInfoBeforePurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:] as [String: Any],
                "non_subscriptions": [:] as [String: Any]
            ] as [String: Any]
        ])
        self.customerInfoAfterPurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:] as [String: Any],
                "non_subscriptions": [self.product.mockProductIdentifier: [] as [Any]]
            ] as [String: Any]
        ])

        self.setupPurchases()
    }

    private var delegate: StoreKit1WrapperDelegate {
        get throws {
            return try XCTUnwrap(self.storeKit1Wrapper.delegate)
        }
    }

    func testDelegateIsCalledForRandomPurchaseSuccess() throws {
        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        let payment = SKPayment(product: self.product)

        self.backend.overrideCustomerInfoResult = .success(self.customerInfoBeforePurchase)
        self.backend.postReceiptResult = .success(self.customerInfoAfterPurchase)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsOnlyCalledOnceIfCustomerInfoTheSame() throws {
        let customerInfo1: CustomerInfo = .emptyInfo
        let customerInfo2 = customerInfo1

        let payment = SKPayment(product: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment
        transaction.mockState = .purchasing

        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo1)
        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo2)
        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsCalledTwiceIfCustomerInfoTheDifferent() throws {
        let delegateReceivedCount = self.purchasesDelegate.customerInfoReceivedCount

        let payment = SKPayment(product: self.product)

        let transaction1 = MockTransaction()
        transaction1.mockPayment = payment
        transaction1.mockState = .purchasing

        let transaction2 = MockTransaction()
        transaction2.mockPayment = payment
        transaction2.mockState = .purchasing

        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction1)
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction2)

        self.backend.postReceiptResult = .success(self.customerInfoBeforePurchase)
        transaction1.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction1)

        self.backend.postReceiptResult = .success(self.customerInfoAfterPurchase)
        transaction2.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction2)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(delegateReceivedCount + 2))
    }

    func testDelegateIsCalledOnceIfTransactionWasAlreadyPosted() throws {
        let delegateReceivedCount = self.purchasesDelegate.customerInfoReceivedCount

        let payment = SKPayment(product: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment
        transaction.mockState = .purchasing

        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(self.customerInfoBeforePurchase)
        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(self.customerInfoAfterPurchase)
        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(delegateReceivedCount + 1))
    }

    func testDoesntIgnorePurchasesThatDoNotHaveApplicationUserNames() throws {
        let transaction = MockTransaction()
        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        expect(payment.applicationUsername).to(beNil())

        transaction.mockPayment = payment
        transaction.mockState = .purchased

        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testProductIsRemovedButPresentInTheQueuedTransaction() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])

        self.backend.overrideCustomerInfoResult = .success(self.customerInfoBeforePurchase)
        self.backend.postReceiptResult = .success(self.customerInfoAfterPurchase)

        let payment = SKPayment(product: self.product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = .purchasing
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        transaction.mockState = .purchased
        try self.delegate.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedInitiationSource) == .queue
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

}
