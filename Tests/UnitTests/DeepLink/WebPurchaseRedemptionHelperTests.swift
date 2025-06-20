//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebPurchaseRedemptionHelperTests.swift
//
//  Created by Antonio Rico Diez on 6/11/24.

import Nimble
@testable import RevenueCat
import XCTest

class WebPurchaseRedemptionHelperTests: TestCase {

    fileprivate var backend: MockBackend!
    fileprivate var redeemWebPurchaseAPI: MockRedeemWebPurchaseAPI!
    fileprivate var identityManager: MockIdentityManager!
    fileprivate var customerInfoManager: MockCustomerInfoManager!

    fileprivate var helper: WebPurchaseRedemptionHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let systemInfo = MockSystemInfo(finishTransactions: true)
        let deviceCache = MockDeviceCache(systemInfo: systemInfo)

        self.backend = MockBackend()
        // swiftlint:disable:next force_cast
        self.redeemWebPurchaseAPI = (self.backend.redeemWebPurchaseAPI as! MockRedeemWebPurchaseAPI)
        self.identityManager = MockIdentityManager(mockAppUserID: "test-user-id", mockDeviceCache: deviceCache)
        self.customerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: MockOperationDispatcher(),
            deviceCache: deviceCache,
            backend: self.backend,
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: MockTransactionPoster(),
            systemInfo: systemInfo
        )

        self.helper = WebPurchaseRedemptionHelper(backend: backend,
                                                  identityManager: identityManager,
                                                  customerInfoManager: customerInfoManager)
    }

    func testHandleRedeemWebPurchaseSuccess() async throws {
        let expectedCustomerInfo = CustomerInfo(testData: BaseBackendLoginTests.validCustomerResponse)!
        self.redeemWebPurchaseAPI.stubbedPostRedeemWebPurchaseResult = .success(expectedCustomerInfo)

        let result = await self.helper.handleRedeemWebPurchase(redemptionToken: "test-redemption-token")

        var receivedCustomerInfo: CustomerInfo?

        switch result {
        case let .success(customerInfo):
            receivedCustomerInfo = customerInfo
        default:
            XCTFail("Should be a success.")
        }

        expect(self.customerInfoManager.invokedCacheCustomerInfoParameters).to(equal(
            (expectedCustomerInfo, "test-user-id")
        ))

        expect(receivedCustomerInfo) == expectedCustomerInfo
    }

    func testHandleRedeemWebPurchaseInvalidToken() async throws {
        self.redeemWebPurchaseAPI.stubbedPostRedeemWebPurchaseResult = .failure(.invalidWebRedemptionToken)

        let result = await self.helper.handleRedeemWebPurchase(redemptionToken: "test-redemption-token")

        var receivedExpectedError: Bool = false

        switch result {
        case .invalidToken:
            receivedExpectedError = true
        default:
            XCTFail("Should be a invalid token error.")
        }

        expect(receivedExpectedError) == true
    }

    func testHandleRedeemWebPurchaseBelongsToOtherUser() async throws {
        self.redeemWebPurchaseAPI.stubbedPostRedeemWebPurchaseResult = .failure(.purchaseBelongsToOtherUser)

        let result = await self.helper.handleRedeemWebPurchase(redemptionToken: "test-redemption-token")

        var receivedExpectedError: Bool = false

        switch result {
        case .purchaseBelongsToOtherUser:
            receivedExpectedError = true
        default:
            XCTFail("Should be a purchase belongs to other user error.")
        }

        expect(receivedExpectedError) == true
    }

    func testHandleRedeemWebPurchaseExpired() async throws {
        self.redeemWebPurchaseAPI.stubbedPostRedeemWebPurchaseResult = .failure(
            .expiredWebRedemptionToken(obfuscatedEmail: "test-obfuscated-email")
        )

        let result = await self.helper.handleRedeemWebPurchase(redemptionToken: "test-redemption-token")

        var receivedObfuscatedEmail: String?

        switch result {
        case let .expired(obfuscatedEmail):
            receivedObfuscatedEmail = obfuscatedEmail
        default:
            XCTFail("Should be a expired error.")
        }

        expect(receivedObfuscatedEmail) == "test-obfuscated-email"
    }
}
