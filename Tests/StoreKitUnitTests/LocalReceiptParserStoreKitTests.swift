//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalReceiptParserStoreKitTests.swift
//
//  Created by Andrés Boedo on 4/4/22.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class LocalReceiptParserStoreKitTests: StoreKitConfigTestCase {

    private let operationDispatcher: OperationDispatcher = .default
    private let receiptRefreshRequestFactory = ReceiptRefreshRequestFactory()
    private var requestFetcher: StoreKitRequestFetcher!
    private var systemInfo: SystemInfo!
    private var receiptFetcher: ReceiptFetcher!
    private var parser: PurchasesReceiptParser!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.requestFetcher = StoreKitRequestFetcher(requestFactory: receiptRefreshRequestFactory,
                                                     operationDispatcher: operationDispatcher)

        self.systemInfo = SystemInfo(platformInfo: Purchases.platformInfo,
                                     finishTransactions: true,
                                     operationDispatcher: operationDispatcher,
                                     storeKit2Setting: .disabled)
        self.receiptFetcher = ReceiptFetcher(requestFetcher: self.requestFetcher, systemInfo: systemInfo)
        self.parser = .default
    }

    @MainActor
    func testReceiptParserParsesEmptyReceipt() async throws {
        let data = try await XCTAsyncUnwrap(await self.receiptFetcher.receiptData(refreshPolicy: .always))

        let receipt = try self.parser.parse(from: data)

        expect(receipt.bundleId) == "com.revenuecat.StoreKitUnitTestsHostApp"
        expect(receipt.applicationVersion) == "1"
        expect(receipt.originalApplicationVersion).to(beNil())
        expect(receipt.opaqueValue).toNot(beNil())
        expect(receipt.sha1Hash).toNot(beNil())
        expect(receipt.creationDate).to(beCloseToNow())
        expect(receipt.expirationDate).toNot(beNil())
        expect(receipt.expirationDate).toNot(beCloseToNow())
        expect(receipt.inAppPurchases).to(beEmpty())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testReceiptParserParsesReceiptWithSingleIAP() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        let product = try await fetchSk2Product()
        let purchaseTime = Date()

        _ = try await product.purchase()

        let receiptData = await self.receiptFetcher.receiptData(refreshPolicy: .always)
        let data = try XCTUnwrap(receiptData)

        let receipt = try self.parser.parse(from: data)

        let firstPurchase = try XCTUnwrap(receipt.inAppPurchases.onlyElement)

        expect(firstPurchase.quantity) == 1
        expect(firstPurchase.productId) == product.id
        expect(firstPurchase.transactionId).toNot(beNil())
        expect(firstPurchase.originalTransactionId).to(beNil())
        expect(firstPurchase.productType) == .unknown

        expect(firstPurchase.purchaseDate).to(beCloseTo(purchaseTime, within: 5))
        expect(firstPurchase.originalPurchaseDate).to(beNil())

        expect(firstPurchase.expiresDate).toNot(beNil())
        expect(firstPurchase.expiresDate).toNot(beCloseToNow())

        expect(firstPurchase.isSubscription) == true

        expect(firstPurchase.cancellationDate).to(beNil())
        expect(firstPurchase.isInTrialPeriod).to(beNil())
        expect(firstPurchase.isInIntroOfferPeriod) == true
        expect(firstPurchase.webOrderLineItemId).to(beNil())
        expect(firstPurchase.promotionalOfferIdentifier).to(beNil())

    }

}
