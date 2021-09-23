//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Foundation
import Nimble
import StoreKit
@testable import RevenueCat
import XCTest

class PurchasesOrchestratorTests: XCTestCase {

    var productsManager: MockProductsManager!
    var storeKitWrapper: MockStoreKitWrapper!
    var systemInfo: MockSystemInfo!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var operationDispatcher: MockOperationDispatcher!
    var receiptFetcher: MockReceiptFetcher!
    var customerInfoManager: MockCustomerInfoManager!
    var backend: MockBackend!
    var identityManager: MockIdentityManager!
    var receiptParser: MockReceiptParser!
    var deviceCache: MockDeviceCache!

    var orchestrator: PurchasesOrchestrator!

    override func setUp() {

        productsManager = MockProductsManager()
        storeKitWrapper = MockStoreKitWrapper()
        systemInfo = try! MockSystemInfo(platformFlavor: "xyz",
                                         platformFlavorVersion: "1.2.3",
                                         finishTransactions: true)
        operationDispatcher = MockOperationDispatcher()
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher())
        deviceCache = MockDeviceCache()
        backend = MockBackend()
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: OperationDispatcher(),
                                                        deviceCache: deviceCache,
                                                        backend: backend,
                                                        systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        receiptParser = MockReceiptParser()
        let attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                        systemInfo: systemInfo)
        subscriberAttributesManager = MockSubscriberAttributesManager(backend: backend,
                                                                      deviceCache: deviceCache,
                                                                      attributionFetcher: attributionFetcher,
                                                                      attributionDataMigrator: MockAttributionDataMigrator())

        orchestrator = PurchasesOrchestrator(productsManager: productsManager,
                                             storeKitWrapper: storeKitWrapper,
                                             systemInfo: systemInfo,
                                             subscriberAttributesManager: subscriberAttributesManager,
                                             operationDispatcher: operationDispatcher,
                                             receiptFetcher: receiptFetcher,
                                             customerInfoManager: customerInfoManager,
                                             backend: backend,
                                             identityManager: identityManager,
                                             receiptParser: receiptParser,
                                             deviceCache: deviceCache)
    }
    
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageTriggersAPurchase() async throws {
        guard #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let sk2Product = try! await StoreKit.Product.products(for: ["com.revenuecat.monthly_4.99.1_week_intro"]).first!
        let productDetails = SK2ProductDetails(sk2Product: sk2Product)
        let package = Package(identifier: "package", packageType: .monthly, productDetails: productDetails, offeringIdentifier: "offering")
        var completionCalled = false

        var receivedTransaction: SKPaymentTransaction?
        var receivedPurchaserInfo: PurchaserInfo?
        var receivedError: Error?
        var receivedUserCancelled: Bool?
        orchestrator.purchase(package: package) { maybeTransaction, maybePurchaserInfo, maybeError, userCancelled in
            completionCalled = true

            receivedTransaction = maybeTransaction
            receivedPurchaserInfo = maybePurchaserInfo
            receivedError = maybeError
            receivedUserCancelled = userCancelled
        }

        expect(completionCalled).toEventually(beTrue())
        let nonOptionalReceivedError = try XCTUnwrap(receivedError)
        expect((nonOptionalReceivedError as NSError).code) == ErrorCode.unexpectedBackendResponseError.rawValue
        expect(receivedUserCancelled) == false
        expect(receivedTransaction).to(beNil())
        expect(receivedPurchaserInfo).to(beNil())
    }

    func testPurchaseSK2PackageHandlesPurchaseResult() {

    }

    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() {

    }

    func testPurchaseSK2PackageSkipsIfUserCancelled() {

    }

}
