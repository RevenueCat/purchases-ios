//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsModalHelperTests.swift
//
//  Created by Andrés Boedo on 8/20/21.

import Foundation
import Nimble
@testable import PurchasesCoreSwift
import XCTest
@testable import PurchasesTests

class ManageSubscriptionsModalHelperTests: XCTestCase {

    private var systemInfo: MockSystemInfo!
    private var purchaserInfoManager: MockPurchaserInfoManager!
    private var identityManager: MockIdentityManager!
    private var helper: ManageSubscriptionsModalHelper!
    private let mockPurchaserInfoData: [String: Any] = [
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


    override func setUp() {
        systemInfo = try! MockSystemInfo(platformFlavor: "", platformFlavorVersion: "", finishTransactions: true)
        purchaserInfoManager = MockPurchaserInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                        deviceCache: MockDeviceCache(),
                                                        backend: MockBackend(),
                                                        systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        helper = ManageSubscriptionsModalHelper(systemInfo: systemInfo,
                                                purchaserInfoManager: purchaserInfoManager,
                                                identityManager: identityManager)
    }
    func testShowManageSubscriptionModalMakesRightCalls() throws {
        guard #available(iOS 15.0, *) else { return }
        // given
        var callbackCalled = false
        var receivedResult: Result<Void, ManageSubscriptionsModalError>?
        purchaserInfoManager.stubbedPurchaserInfo = PurchaserInfo(data: mockPurchaserInfoData)

        // when
        helper.showManageSubscriptionModal { result in
            callbackCalled = true
            receivedResult = result
        }

        // then
        expect(callbackCalled).toEventually(beTrue())
        expect(self.purchaserInfoManager.invokedPurchaserInfo) == true
        let nonNilReceivedResult: Result<Void, ManageSubscriptionsModalError> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beSuccess())
    }
}

