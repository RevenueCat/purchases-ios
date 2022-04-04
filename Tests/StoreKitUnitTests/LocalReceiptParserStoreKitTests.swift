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
@testable import RevenueCat
import Nimble
import XCTest

class LocalReceiptParserStoreKitTests: StoreKitConfigTestCase {

    func testReceiptParserParsesEmptyReceipt() throws {

        let operationDispatcher: OperationDispatcher = .default
        let receiptRefreshRequestFactory = ReceiptRefreshRequestFactory()
        let fetcher = StoreKitRequestFetcher(requestFactory: receiptRefreshRequestFactory,
                                             operationDispatcher: operationDispatcher)
        let systemInfo: SystemInfo
        do {
            systemInfo = try SystemInfo(platformInfo: Purchases.platformInfo,
                                        finishTransactions: true,
                                        operationDispatcher: operationDispatcher,
                                        useStoreKit2IfAvailable: false)
        } catch {
            fatalError(error.localizedDescription)
        }

        let receiptFetcher = ReceiptFetcher(requestFetcher: fetcher, systemInfo: systemInfo)
        let parser = ReceiptParser()
        var maybeReceipt: AppleReceipt?
        var completionCalled = false
        receiptFetcher.receiptData(refreshPolicy: .always) { data in
            guard let data = data else { return }
            do {
                maybeReceipt = try parser.parse(from: data)
                completionCalled = true
            } catch {
                print("failed to parse. Error: \(error)")
                completionCalled = true
            }
        }

        expect(completionCalled).toEventually(beTrue())
        let receipt = try XCTUnwrap(maybeReceipt)
        expect(receipt.applicationVersion) == "1"
    }

}
