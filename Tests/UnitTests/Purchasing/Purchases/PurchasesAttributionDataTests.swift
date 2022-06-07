//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesAttributionDataTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesAttributionDataTests: BasePurchasesTests {

    func testAddAttributionAlwaysAddsAdIdsEmptyDict() throws {
        self.setupPurchases()

        Purchases.deprecated.addAttributionData([:], fromNetwork: .adjust)

        let attributionData = try XCTUnwrap(
            self.subscriberAttributesManager
                .invokedConvertAttributionDataAndSetParameters?
                .attributionData
        )

        expect(attributionData.count) == 2
        expect(attributionData["rc_idfa"] as? String) == "rc_idfa"
        expect(attributionData["rc_idfv"] as? String) == "rc_idfv"
    }

    func testAttributionDataIsPostponedIfThereIsNoInstance() throws {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: .appsFlyer)

        self.setupPurchases()

        let invokedParameters = try XCTUnwrap(
            self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParameters
        )

        for key in data.keys {
            expect(invokedParameters.attributionData.keys.contains(key)).toEventually(beTrue())
        }

        expect(invokedParameters.attributionData.keys.contains("rc_idfa")) == true
        expect(invokedParameters.attributionData.keys.contains("rc_idfv")) == true
        expect(invokedParameters.network) == .appsFlyer
        expect(invokedParameters.appUserID) == self.purchases?.appUserID
    }

}
