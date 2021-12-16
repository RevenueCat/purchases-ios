//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsHelperTests.swift
//
//  Created by Andrés Boedo on 8/20/21.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

#if os(macOS) || os(iOS)

class ManageSubscriptionsHelperTests: XCTestCase {

    private var systemInfo: MockSystemInfo!
    private var customerInfoManager: MockCustomerInfoManager!
    private var identityManager: MockIdentityManager!
    private var helper: ManageSubscriptionsHelper!
    private let mockCustomerInfoData: [String: Any] = [
        "request_date": "2018-12-21T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "first_seen": "2019-06-17T16:05:33Z",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ],
        "managementURL": NSNull()
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()
        systemInfo = MockSystemInfo(finishTransactions: true)
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                      deviceCache: MockDeviceCache(systemInfo: systemInfo),
                                                      backend: MockBackend(),
                                                      systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        helper = ManageSubscriptionsHelper(systemInfo: systemInfo,
                                           customerInfoManager: customerInfoManager,
                                           identityManager: identityManager)
    }

    func testShowManageSubscriptionsMakesRightCalls() throws {
        guard #available(iOS 15.0, *) else { throw XCTSkip("Required API is not available for this test.") }
        // given
        var callbackCalled = false
        customerInfoManager.stubbedCustomerInfo = try CustomerInfo(data: mockCustomerInfoData)

        // when
        helper.showManageSubscriptions { _ in
            callbackCalled = true
        }

        // then
        expect(callbackCalled).toEventually(beTrue())
        expect(self.customerInfoManager.invokedCustomerInfo) == true

        // we'd ideally also patch the UIApplication (or NSWorkspace for mac), as well as
        // AppStore, and check for the calls in those, but it gets very tricky.
    }

    func testShowManageSubscriptionsInIOS() throws {
        guard #available(iOS 10.0, *) else {
            throw XCTSkip("Not supported")
        }

        // given
        var callbackCalled = false
        var receivedResult: Result<Void, Error>?
        customerInfoManager.stubbedCustomerInfo = try CustomerInfo(data: mockCustomerInfoData)

        // when
        helper.showManageSubscriptions { result in
            callbackCalled = true
            receivedResult = result
        }

        // then
        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<Void, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beSuccess())
    }

    func testShowManageSubscriptionsSucceedsInMacOS() throws {
        guard #available(macOS 11.0, *) else {
            throw XCTSkip("Not supported")
        }

        // given
        var callbackCalled = false
        var receivedResult: Result<Void, Error>?
        customerInfoManager.stubbedCustomerInfo = try CustomerInfo(data: mockCustomerInfoData)

        // when
        helper.showManageSubscriptions { result in
            callbackCalled = true
            receivedResult = result
        }

        // then
        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<Void, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beSuccess())
    }

    func testShowManageSubscriptionsFailsIfCouldntGetCustomerInfo() throws {
        // given
        var callbackCalled = false
        var receivedResult: Result<Void, Error>?
        customerInfoManager.stubbedError = NSError(domain: RCPurchasesErrorCodeDomain, code: 123, userInfo: nil)

        // when
        helper.showManageSubscriptions { result in
            callbackCalled = true
            receivedResult = result
        }

        // then
        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<Void, Error> = try XCTUnwrap(receivedResult)
        let expectedErrorMessage = "Failed to get managementURL from CustomerInfo. " +
        "Details: The operation couldn’t be completed"
        let expectedError = ErrorUtils.customerInfoError(withMessage: expectedErrorMessage,
                                                         error: customerInfoManager.stubbedError)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

}

#endif
