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

#if os(macOS) || os(iOS) || VISION_OS

class ManageSubscriptionsHelperTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var customerInfoManager: MockCustomerInfoManager!
    private var currentUserProvider: CurrentUserProvider!
    private var helper: ManageSubscriptionsHelper!
    private let mockCustomerInfoData: [String: Any] = [
        "request_date": "2018-12-21T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "first_seen": "2019-06-17T16:05:33Z",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any],
        "managementURL": NSNull()
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = MockSystemInfo(finishTransactions: true)
        self.customerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: MockOperationDispatcher(),
            deviceCache: MockDeviceCache(sandboxEnvironmentDetector: self.systemInfo),
            backend: MockBackend(),
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: MockTransactionPoster(),
            systemInfo: self.systemInfo
        )
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: "appUserID")
        self.helper = ManageSubscriptionsHelper(systemInfo: self.systemInfo,
                                                customerInfoManager: self.customerInfoManager,
                                                currentUserProvider: self.currentUserProvider)
    }

    func testShowManageSubscriptions() throws {
        // given
        var receivedResult: Result<Void, PurchasesError>?
        customerInfoManager.stubbedCustomerInfoResult = .success(try CustomerInfo(data: mockCustomerInfoData))

        // when
        helper.showManageSubscriptions { result in
            receivedResult = result
        }

        // then
        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult).to(beSuccess())
    }

    func testShowManageSubscriptionsFailsIfCouldntGetCustomerInfo() throws {
        let error: BackendError = .networkError(.errorResponse(
            .init(code: .badRequest,
                  originalCode: BackendErrorCode.badRequest.rawValue,
                  message: nil,
                  attributeErrors: [:]),
            400)
        )

        // given
        var receivedResult: Result<Void, PurchasesError>?
        customerInfoManager.stubbedCustomerInfoResult = .failure(error)

        // when
        helper.showManageSubscriptions { result in
            receivedResult = result
        }

        // then
        expect(receivedResult).toEventuallyNot(beNil())

        let nonNilReceivedResult = try XCTUnwrap(receivedResult)
        let expectedErrorMessage = "Failed to get managementURL from CustomerInfo. " +
        "Details: The operation couldn’t be completed"
        let expectedError = ErrorUtils.customerInfoError(withMessage: expectedErrorMessage,
                                                         error: error)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

}

#endif
