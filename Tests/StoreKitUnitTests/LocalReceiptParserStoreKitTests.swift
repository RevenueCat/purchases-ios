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

class LocalReceiptParserStoreKitTests: StoreKitConfigTestCase {

    let operationDispatcher: OperationDispatcher = .default
    let receiptRefreshRequestFactory = ReceiptRefreshRequestFactory()
    var requestFetcher: StoreKitRequestFetcher!
    var systemInfo: SystemInfo!
    var receiptFetcher: ReceiptFetcher!
    var parser: ReceiptParser!

    override func setUpWithError() throws {
        try super.setUpWithError()
        requestFetcher = StoreKitRequestFetcher(requestFactory: receiptRefreshRequestFactory,
                                                operationDispatcher: operationDispatcher)

        systemInfo = try SystemInfo(platformInfo: Purchases.platformInfo,
                                    finishTransactions: true,
                                    operationDispatcher: operationDispatcher,
                                    storeKit2Setting: .disabled)
        receiptFetcher = ReceiptFetcher(requestFetcher: requestFetcher, systemInfo: systemInfo)
        parser = ReceiptParser()
    }

    func testReceiptParserParsesEmptyReceipt() async throws {
        let data = try await XCTAsyncUnwrap(await self.receiptFetcher.receiptData(refreshPolicy: .always))

        let receipt = try self.parser.parse(from: data)

        expect(receipt.bundleId) == "com.revenuecat.StoreKitUnitTestsHostApp"
        expect(receipt.applicationVersion) == "1"
        expect(receipt.originalApplicationVersion).to(beNil())
        expect(receipt.opaqueValue).toNot(beNil())
        expect(receipt.sha1Hash).toNot(beNil())
        expect(receipt.creationDate).to(beCloseTo(Date(), within: 1))
        expect(receipt.expirationDate).toNot(beNil())
        expect(receipt.expirationDate).toNot(beCloseTo(Date(), within: 1))
        expect(receipt.inAppPurchases).to(beEmpty())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testReceiptParserParsesReceiptWithSingleIAP() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        let product = try await fetchSk2Product()
        _ = try await product.purchase()

        let data = try await XCTAsyncUnwrap(await receiptFetcher.receiptData(refreshPolicy: .always))

        let receipt = try self.parser.parse(from: data)

        let firstPurchase = try XCTUnwrap(receipt.inAppPurchases.onlyElement)

        expect(firstPurchase.quantity) == 1
        expect(firstPurchase.productId) == product.id
        expect(firstPurchase.transactionId).toNot(beNil())
        expect(firstPurchase.originalTransactionId).to(beNil())
        expect(firstPurchase.productType).to(beNil())

        expect(firstPurchase.purchaseDate).to(beCloseTo(Date(), within: 5))
        expect(firstPurchase.originalPurchaseDate).to(beNil())

        expect(firstPurchase.expiresDate).toNot(beNil())
        expect(firstPurchase.expiresDate).toNot(beCloseTo(Date(), within: 1))

        expect(firstPurchase.cancellationDate).to(beNil())
        expect(firstPurchase.isInTrialPeriod).to(beNil())
        expect(firstPurchase.isInIntroOfferPeriod) == true
        expect(firstPurchase.webOrderLineItemId).to(beNil())
        expect(firstPurchase.promotionalOfferIdentifier).to(beNil())

    }

}
