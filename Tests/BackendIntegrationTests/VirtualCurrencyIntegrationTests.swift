//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyIntegrationTests.swift
//
//  Created by Will Taylor on 6/29/25.

import Nimble
import Foundation
@testable import RevenueCat
import XCTest

class VirtualCurrencyStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {
    override class var storeKitVersion: StoreKitVersion { .storeKit2 }
}

class VirtualCurrencyStoreKit1IntegrationTests: BaseStoreKitIntegrationTests {

    override var apiKey: String { return Constants.loadShedderApiKey }

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testGrantsVCForProductWithVCGrant() async throws {
        let userID1 = "vc_user_\(UUID().uuidString)"
        let userID2 = "vc_user_\(UUID().uuidString)"

        _ = try await self.purchases.logIn(userID1)

        try self.purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrenciesBeforePurchase = try await self.purchases.virtualCurrencies()

        // TODO: We might need to check for this to be 0 depending on the outcome from a discussion with
        // the team
        expect(virtualCurrenciesBeforePurchase["TEST"]?.balance).to(beNil())
        expect(virtualCurrenciesBeforePurchase["TEST2"]?.balance).to(beNil())

        try await self.purchaseConsumablePackage()

        try self.purchases.invalidateVirtualCurrenciesCache()

        let virtualCurrenciesAfterPurchase = try await self.purchases.virtualCurrencies()

        expect(virtualCurrenciesAfterPurchase["TEST"]?.balance).to(equal(1))
        expect(virtualCurrenciesAfterPurchase["TEST2"]?.balance).to(equal(0))
    }
}
