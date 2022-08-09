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

    @available(*, deprecated)
    func testPassesTheArrayForAllNetworks() {
        self.setupPurchases()

        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: .appleSearchAds)

        for key in data.keys {
            expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains(key))
                .toEventually(beTrue())
        }
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfa")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfv")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].network) == .appleSearchAds
        expect(self.backend.invokedPostAttributionDataParametersList[0].appUserID) == self.purchases?.appUserID
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

    @available(*, deprecated)
    func testAttributionDataSendsNetworkAppUserId() throws {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data,
                                                from: .appleSearchAds,
                                                forNetworkUserId: "newuser")

        self.setupPurchases()

        expect(self.backend.invokedPostAttributionData).toEventually(beTrue())

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)
        for key in data.keys {
            expect(invokedMethodParams.data?.keys.contains(key)).to(beTrue())
        }

        expect(invokedMethodParams.data?.keys.contains("rc_idfa")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_idfv")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_attribution_network_id")) == true
        expect(invokedMethodParams.data?["rc_attribution_network_id"] as? String) == "newuser"
        expect(invokedMethodParams.network) == .appleSearchAds
        expect(invokedMethodParams.appUserID) == identityManager.currentAppUserID
    }

    @available(*, deprecated)
    func testAttributionDataDontSendNetworkAppUserIdIfNotProvided() throws {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: .appleSearchAds)

        self.setupPurchases()

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)
        for key in data.keys {
            expect(invokedMethodParams.data?.keys.contains(key)) == true
        }

        expect(invokedMethodParams.data?.keys.contains("rc_idfa")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_idfv")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_attribution_network_id")) == false
        expect(invokedMethodParams.network) == .appleSearchAds
        expect(invokedMethodParams.appUserID) == identityManager.currentAppUserID
    }

    @available(*, deprecated)
    func testAdClientAttributionDataIsAutomaticallyCollected() throws {
        self.setupPurchases(automaticCollection: true)

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)

        expect(invokedMethodParams).toNot(beNil())
        expect(invokedMethodParams.network) == .appleSearchAds

        let obtainedVersionData = try XCTUnwrap(invokedMethodParams.data?["Version3.1"] as? NSDictionary)
        expect(obtainedVersionData["iad-campaign-id"]).toNot(beNil())
    }

    func testAdClientAttributionDataIsNotAutomaticallyCollectedIfDisabled() {
        self.setupPurchases(automaticCollection: false)
        expect(self.backend.invokedPostAttributionDataParameters).to(beNil())
    }

    func testAttributionDataPostponesMultiple() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, from: .adjust, forNetworkUserId: "newuser")

        self.setupPurchases(automaticCollection: true)

        expect(self.backend.invokedPostAttributionDataParametersList).toEventually(haveCount(1))
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParametersList).to(haveCount(1))
    }

}
