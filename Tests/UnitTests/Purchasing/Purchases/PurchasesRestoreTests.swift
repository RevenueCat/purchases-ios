//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesRestoreTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesRestoreTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testRestoresDontPostMissingReceipts() {
        self.receiptFetcher.shouldReturnReceipt = false

        let receivedError = waitUntilValue { completed in
            self.purchases.restorePurchases { (_, error) in
                completed(error as NSError?)
            }
        }

        expect(receivedError).to(matchError(ErrorCode.missingReceiptFileError))
    }

    func testRestorePurchasesCallsCompletionOnMainThreadWhenMissingReceipts() {
        self.receiptFetcher.shouldReturnReceipt = false
        let receivedError: NSError? = waitUntilValue { completed in
            self.purchases.restorePurchases { (_, error) in
                expect(Thread.isMainThread) == true
                completed(error as NSError?)
            }
        }

        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) >= 1
        expect(receivedError).to(matchError(ErrorCode.missingReceiptFileError))
    }

    func testRestoringPurchasesPostsTheReceipt() {
        self.purchases.restorePurchases()
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testRestoringPurchasesPostsIfReceiptEmptyAndCustomerInfoNotLoaded() {
        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        self.purchases.restorePurchases()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)

        let object = try info.jsonEncodedData
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        self.purchases.restorePurchases()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoNotLoaded() {
        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        self.purchases.restorePurchases()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesAlwaysRefreshesAndPostsTheReceipt() {
        self.receiptFetcher.shouldReturnReceipt = true
        self.purchases.restorePurchases()

        expect(self.receiptFetcher.receiptDataTimesCalled).to(equal(1))
    }

    func testRestoringPurchasesPostsProductRequestDataForActiveSubscription() {
        let productIdentifier = "com.revenuecat.product"
        let product = MockSK1Product(mockProductIdentifier: productIdentifier)
        product.mockPrice = 2.99

        self.receiptFetcher.shouldReturnReceipt = true
        self.mockReceiptParser.stubbedParseResult = .init(
            bundleId: "",
            applicationVersion: "",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: [
                .init(quantity: 1,
                      productId: "consumable",
                      transactionId: "1",
                      originalTransactionId: nil,
                      productType: .consumable,
                      purchaseDate: Date(),
                      originalPurchaseDate: nil,
                      expiresDate: Date().addingTimeInterval(10000),
                      cancellationDate: nil,
                      isInTrialPeriod: false,
                      isInIntroOfferPeriod: false,
                      webOrderLineItemId: nil,
                      promotionalOfferIdentifier: nil),
                .init(quantity: 1,
                      productId: productIdentifier,
                      transactionId: "2",
                      originalTransactionId: nil,
                      productType: .autoRenewableSubscription,
                      purchaseDate: Date(),
                      originalPurchaseDate: nil,
                      expiresDate: Date().addingTimeInterval(10000),
                      cancellationDate: nil,
                      isInTrialPeriod: false,
                      isInIntroOfferPeriod: false,
                      webOrderLineItemId: nil,
                      promotionalOfferIdentifier: nil),
                .init(quantity: 1,
                      productId: "expired sub",
                      transactionId: "3",
                      originalTransactionId: nil,
                      productType: .autoRenewableSubscription,
                      purchaseDate: Date(),
                      originalPurchaseDate: nil,
                      expiresDate: Date().addingTimeInterval(-100),
                      cancellationDate: nil,
                      isInTrialPeriod: false,
                      isInIntroOfferPeriod: false,
                      webOrderLineItemId: nil,
                      promotionalOfferIdentifier: nil),
                .init(quantity: 1,
                      productId: "older subscription",
                      transactionId: "4",
                      originalTransactionId: nil,
                      productType: .autoRenewableSubscription,
                      purchaseDate: Date().addingTimeInterval(-100000),
                      originalPurchaseDate: nil,
                      expiresDate: Date().addingTimeInterval(10000),
                      cancellationDate: nil,
                      isInTrialPeriod: false,
                      isInIntroOfferPeriod: false,
                      webOrderLineItemId: nil,
                      promotionalOfferIdentifier: nil)
            ]
        )
        self.mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        self.purchases.restorePurchases()

        expect(self.mockProductsManager.invokedProductsCount) == 1
        expect(self.mockProductsManager.invokedProductsParameters) == [productIdentifier]

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1

        expect(self.backend.postedReceiptData) == EncodedAppleReceipt(receipt: self.receiptFetcher.mockReceiptData)
        expect(self.backend.postedProductID) == productIdentifier
        expect(self.backend.postedPrice) == product.price as Decimal
        expect(self.backend.postedCurrencyCode) == "USD"
        expect(self.backend.postedDiscounts).to(beEmpty())
    }

    func testRestoringPurchasesSetsIsRestore() {
        self.purchases.restorePurchases()
        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesSetsIsRestoreForAnon() {
        Purchases.clearSingleton()
        self.setupAnonPurchases()

        self.purchases.restorePurchases()

        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesCallsSuccessDelegateMethod() throws {
        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        let receivedCustomerInfo = waitUntilValue { completed in
            self.purchases.restorePurchases { (info, _) in
                completed(info)
            }
        }

        expect(receivedCustomerInfo) === customerInfo
    }

    func testRestorePurchasesPassesErrorOnFailure() {
        let error: BackendError = .missingAppUserID()

        self.backend.postReceiptResult = .failure(error)
        self.purchasesDelegate.customerInfo = nil

        let receivedError = waitUntilValue { completed in
            self.purchases.restorePurchases { (_, newError) in
                completed(newError)
            }
        }

        expect(receivedError).to(matchError(error.asPurchasesError))
    }

    func testFetchVersionSendsAReceiptIfNoVersion() throws {
        self.backend.postReceiptResult = .success(try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": Self.appUserID,
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ] as [String: Any]
        ]))

        let receivedCustomerInfo = waitUntilValue { completed in
            self.purchases.restorePurchases { (info, _) in
                completed(info)
            }
        }

        expect(receivedCustomerInfo?.originalApplicationVersion) == "1.0"
        expect(receivedCustomerInfo?.originalPurchaseDate) == Date(timeIntervalSinceReferenceDate: 562288673)
        expect(self.backend.userID).toNot(beNil())
        expect(self.backend.postReceiptDataCalled) == true
    }

}

class PurchasesRestoreNoSetupTests: BasePurchasesTests {

    func testRestoringPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ] as [String: Any]
        ])

        let object = try info.jsonEncodedData

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = object

        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        self.setupPurchases()
        self.purchases.restorePurchases()

        expect(self.backend.postReceiptDataCalled) == false
    }

}
