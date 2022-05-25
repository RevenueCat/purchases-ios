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
        var receivedError: NSError?
        self.purchases.restorePurchases { (_, error) in
            receivedError = error as NSError?
        }

        expect(receivedError?.code).toEventually(equal(ErrorCode.missingReceiptFileError.rawValue))
    }

    func testRestorePurchasesCallsCompletionOnMainThreadWhenMissingReceipts() {
        self.receiptFetcher.shouldReturnReceipt = false
        var receivedError: NSError?
        self.purchases.restorePurchases { (_, error) in
            receivedError = error as NSError?
        }

        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
        expect(receivedError?.code).toEventually(equal(ErrorCode.missingReceiptFileError.rawValue))
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

        let object = try info.asData()
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

    func testRestoringPurchasesSetsIsRestore() {
        self.purchases.restorePurchases()
        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesSetsIsRestoreForAnon() {
        self.setupAnonPurchases()
        self.purchases.restorePurchases()

        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesCallsSuccessDelegateMethod() throws {
        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        var receivedCustomerInfo: CustomerInfo?

        self.purchases.restorePurchases { (info, _) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo).toEventually(be(customerInfo))
    }

    func testRestorePurchasesPassesErrorOnFailure() {
        let error: BackendError = .missingAppUserID()

        self.backend.postReceiptResult = .failure(error)
        self.purchasesDelegate.customerInfo = nil

        var receivedError: Error?

        self.purchases.restorePurchases { (_, newError) in
            receivedError = newError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError).to(matchError(error.asPurchasesError))
    }

    func testFetchVersionSendsAReceiptIfNoVersion() throws {
        self.backend.postReceiptResult = .success(try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": Self.appUserID,
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]
        ]))

        var receivedCustomerInfo: CustomerInfo?

        self.purchases.restorePurchases { (info, _) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo?.originalApplicationVersion).toEventually(equal("1.0"))
        expect(receivedCustomerInfo?.originalPurchaseDate)
            .toEventually(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
        expect(self.backend.userID).toEventuallyNot(beNil())
        expect(self.backend.postReceiptDataCalled).toEventuallyNot(beFalse())
    }

}

class PurchasesRestoreNoSetupTests: BasePurchasesTests {

    func testRestoringPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]])

        let object = try info.asData()

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = object

        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        self.setupPurchases()
        self.purchases.restorePurchases()

        expect(self.backend.postReceiptDataCalled) == false
    }

}
