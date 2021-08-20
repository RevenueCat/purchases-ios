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

class ManageSubscriptionsModalHelperTests: XCTestCase {

    private var systemInfo: MockSystemInfo!
    private var purchaserInfoManager: MockPurchaserInfoManager!
    private var identityManager: MockIdentityManager!
    private var helper: ManageSubscriptionsModalHelper!

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
    func testShowManageSubscriptionModal() {
        helper.showManageSubscriptionModal()
    }
}

