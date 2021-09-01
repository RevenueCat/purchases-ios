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
import XCTest

@testable import Purchases

class PurchasesOrchestratorTests: XCTestCase {

    var productsManager: MockProductsManager!
    var storeKitWrapper: MockStoreKitWrapper!
    var systemInfo: MockSystemInfo!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var operationDispatcher: MockOperationDispatcher!
    var receiptFetcher: MockReceiptFetcher!
    var purchaserInfoManager: MockPurchaserInfoManager!
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
        purchaserInfoManager = MockPurchaserInfoManager(operationDispatcher: OperationDispatcher(),
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
                                             purchaserInfoManager: purchaserInfoManager,
                                             backend: backend,
                                             identityManager: identityManager,
                                             receiptParser: receiptParser,
                                             deviceCache: deviceCache)
    }
}
