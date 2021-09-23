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

class PurchasesOrchestratorTests: StoreKitConfigTestCase {

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

    override func setUpWithError() throws {
        try super.setUpWithError()

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
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            orchestrator.storeKit2Listener = MockStoreKit2Listener()
        }
    }
    
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCorrectValues() async throws {

        guard #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        purchaserInfoManager.stubbedCachedPurchaserInfoResult = mockPurchaserInfo
        backend.stubbedPostReceiptPurchaserInfo = mockPurchaserInfo

        let sk2Product = try! await fetchSk2Product()
        let productDetails = SK2ProductDetails(sk2Product: sk2Product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              productDetails: productDetails,
                              offeringIdentifier: "offering")

        let (transaction, purchaserInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(package: package) { transaction, purchaserInfo, error, userCancelled in
                continuation.resume(returning: (transaction, purchaserInfo, error, userCancelled))
            }
        }

        expect(transaction).to(beNil())
        expect(userCancelled) == false
        expect(error).to(beNil())
        expect(purchaserInfo) == PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
    }

    func testPurchaseSK2PackageHandlesPurchaseResult() {

    }

    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() {

    }

    func testPurchaseSK2PackageSkipsIfUserCancelled() {

    }

}

private extension PurchasesOrchestratorTests {

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func fetchSk2Product() async throws -> SK2Product {
        return try! await StoreKit.Product.products(for: ["com.revenuecat.monthly_4.99.1_week_intro"]).first!
    }

    var mockPurchaserInfo: PurchaserInfo {
        PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])!
    }

}
