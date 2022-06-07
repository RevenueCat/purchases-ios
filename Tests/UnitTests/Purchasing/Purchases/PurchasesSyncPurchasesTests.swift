//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesSyncPurchasesTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesSyncPurchasesTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testSyncPurchasesPostsTheReceipt() {
        self.purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testSyncPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]])

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        self.purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == false
    }

    func testSyncPurchasesPostsIfReceiptEmptyAndCustomerInfoNotLoaded() {
        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        self.purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]])

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        self.purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoNotLoaded() {
        self.mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        self.purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfNotEmpty() {
        self.receiptFetcher.shouldReturnReceipt = true
        self.purchases.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfEmpty() {
        self.receiptFetcher.shouldReturnReceipt = false
        self.purchases.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesPassesIsRestoreAsAllowSharingAppStoreAccount() {
        var deprecated = self.purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        self.purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        self.purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

    func testSyncPurchasesCallsSuccessDelegateMethod() throws {
        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        var receivedCustomerInfo: CustomerInfo?

        self.purchases.syncPurchases { (info, _) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo).toEventually(be(customerInfo))
    }

    func testSyncPurchasesPassesErrorOnFailure() {
        let error: BackendError = .missingAppUserID()

        self.backend.postReceiptResult = .failure(error)
        self.purchasesDelegate.customerInfo = nil

        var receivedError: Error?

        self.purchases.syncPurchases { (_, newError) in
            receivedError = newError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError).to(matchError(error.asPurchasesError))
    }

    func testSyncPurchasesPostsTheReceiptIfAutoSyncPurchasesSettingIsOff() throws {
        self.systemInfo = try MockSystemInfo(platformInfo: nil,
                                             finishTransactions: false,
                                             dangerousSettings: DangerousSettings(autoSyncPurchases: false))
        self.initializePurchasesInstance(appUserId: nil)

        self.purchases.syncPurchases(completion: nil)
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 7.0, *)
    func testSyncsPurchasesIfEntitlementsRevokedForProductIDs() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        expect(self.backend.postReceiptDataCalled) == false
        (self.purchasesOrchestrator as StoreKitWrapperDelegate)
            .storeKitWrapper(self.storeKitWrapper, didRevokeEntitlementsForProductIdentifiers: ["a", "b"])

        expect(self.backend.postReceiptDataCalled) == true
    }

}

class PurchasesSyncPurchasesAnonymousTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupAnonPurchases()
    }

    func testSyncPurchasesSetsIsRestoreForAnon() {
        var deprecated = self.purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        self.purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        self.purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

}
