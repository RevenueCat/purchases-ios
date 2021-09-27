//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsManagerTests.swift
//
//  Created by Juanpe Catalán on 9/8/21.

import XCTest
import Nimble
import StoreKit
@testable import RevenueCat

class OfferingsManagerTests: XCTestCase {

    let mockDeviceCache = MockDeviceCache()
    let mockOperationDispatcher = MockOperationDispatcher()
    let mockSystemInfo = try! MockSystemInfo(platformFlavor: "iOS",
                                             platformFlavorVersion: "3.2.1",
                                             finishTransactions: true)
    let mockBackend = MockBackend()
    let mockOfferingsFactory = MockOfferingsFactory()
    let mockProductsManager = MockProductsManager()
    var offeringsManager: OfferingsManager!

    override func setUp() {
        super.setUp()
        
        offeringsManager = OfferingsManager(deviceCache: mockDeviceCache,
                                            operationDispatcher: mockOperationDispatcher,
                                            systemInfo: mockSystemInfo,
                                            backend: mockBackend,
                                            offeringsFactory: mockOfferingsFactory,
                                            productsManager: mockProductsManager)
    }

}

extension OfferingsManagerTests {

    func testOfferingsForAppUserIDReturnsNilIfMissingProductDetails() {
        // given
        mockOfferingsFactory.emptyOfferings = true
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).toNot(beNil())
        expect(obtainedOfferings!["base"]).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsOfferingsIfSuccessBackendRequest() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).toNot(beNil())
        expect(obtainedOfferings!["base"]).toNot(beNil())
        expect(obtainedOfferings!["base"]!.monthly).toNot(beNil())
        expect(obtainedOfferings!["base"]!.monthly?.product).toNot(beNil())
    }

    func testOfferingsForAppUserIDReturnsNilIfFailBackendRequest() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
    }

    func testOfferingsForAppUserIDReturnsNilIfBackendReturnsNilDataAndNilOfferings() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, nil)
        mockOfferingsFactory.emptyOfferings = true

        // when
        var obtainedOfferings: Offerings?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { offerings, _ in
            obtainedOfferings = offerings
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(obtainedOfferings).to(beNil())
    }


    func testOfferingsForAppUserIDReturnsUnexpectedBackendErrorIfBadBackendRequest() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.badOfferings = true

        // when
        var receivedError: NSError?
        var completionCalled = false
        offeringsManager.offerings(appUserID: MockData.anyAppUserID) { _, error in
            receivedError = error as NSError?
            completionCalled = true
        }

        // then
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        expect(receivedError?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).to(be(ErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testFailBackendDeviceCacheClearsOfferingsCache() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (nil, MockData.unexpectedBackendResponseError)
        mockOfferingsFactory.emptyOfferings = true
        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockDeviceCache.setOfferingsCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockBackend.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.clearOfferingsCacheTimestampCount).toEventually(equal(expectedCallCount))
    }

    func testUpdateOfferingsCacheOK() {
        // given
        mockBackend.stubbedGetOfferingsCompletionResult = (MockData.anyBackendOfferingsData, nil)
        let expectedCallCount = 1

        // when
        offeringsManager.offerings(appUserID: MockData.anyAppUserID, completion: nil)

        // then
        expect(self.mockDeviceCache.setOfferingsCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockBackend.invokedGetOfferingsForAppUserIDCount).toEventually(equal(expectedCallCount))
        expect(self.mockDeviceCache.cacheOfferingsCount).toEventually(equal(expectedCallCount))
    }

    func testGetMissingProductIDs() {
        let productIDs: Set<String> = ["a", "b", "c"]
        let skProducts = ["a" : SKProduct(), "b" : SKProduct()]

        expect(self.offeringsManager.getMissingProductIDs(productsFromStore: [:],
                                                          productIDsFromBackend: productIDs)).to(equal(productIDs))
        expect(self.offeringsManager.getMissingProductIDs(productsFromStore: skProducts,
                                                          productIDsFromBackend: [])).to(equal([]))
        expect(self.offeringsManager.getMissingProductIDs(productsFromStore: skProducts,
                                                          productIDsFromBackend:productIDs)).to(equal(["c"]))
    }

}

private extension OfferingsManagerTests {

    enum MockData {
        static let anyAppUserID = ""
        static let anyBackendOfferingsData: [String: Any] = [
            "offerings": [
                [
                    "identifier": "base",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": "$rc_monthly",
                         "platform_product_identifier": "monthly_freetrial"]
                    ]
                ]
            ],
            "current_offering_id": "base"
        ]
        static let unexpectedBackendResponseError = NSError(domain: RCPurchasesErrorCodeDomain,
                                                            code: ErrorCode.unexpectedBackendResponseError.rawValue,
                                                            userInfo: nil)
    }

}
