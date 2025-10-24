//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FallbackURLBackendIntegrationTests.swift
//
//  Created by Antonio Pallares on 23/10/25.

// swiftlint:disable type_name

import Nimble
@testable import RevenueCat
import SnapshotTesting
import StoreKit
import XCTest

class FallbackURLBackendIntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

//    override var forceServerErrorStrategy: ForceServerErrorStrategy? {
//        return .failExceptFallbackUrls
//    }

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .disabled
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await self.purchases.offerings()

        expect(receivedOfferings.all).toNot(beEmpty())
        assertSnapshot(matching: receivedOfferings.response, as: .formattedJson)
    }

    func testCanGetProductEntitlementMapping() async throws {
        let productEntitlementMapping = try await self.purchases.productEntitlementMapping()

        expect(productEntitlementMapping.entitlementsByProduct).toNot(beEmpty())
        assertSnapshot(matching: productEntitlementMapping.response, as: .formattedJson)
    }

}

