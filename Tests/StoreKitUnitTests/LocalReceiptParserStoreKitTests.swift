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
                                    useStoreKit2IfAvailable: false)
        receiptFetcher = ReceiptFetcher(requestFetcher: requestFetcher, systemInfo: systemInfo)
        parser = ReceiptParser()
    }

    func testReceiptParserParsesEmptyReceipt() async throws {
        let optionalData = await receiptFetcher.receiptData(refreshPolicy: .always)
        let data = try XCTUnwrap(optionalData)

        let receipt = try self.parser.parse(from: data)

        expect(receipt.applicationVersion) == "1"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testReceiptParserParsesReceiptWithSingleIAP() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try await simulateAnyPurchase()

        let optionalData = await receiptFetcher.receiptData(refreshPolicy: .always)
        let data = try XCTUnwrap(optionalData)

        let receipt = try self.parser.parse(from: data)

        expect(receipt.inAppPurchases.count) == 1
    }

}
