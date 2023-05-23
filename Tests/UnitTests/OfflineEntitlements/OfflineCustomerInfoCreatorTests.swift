//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineCustomerInfoCreatorTests.swift
//
//  Created by Nacho Soto on 5/23/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class OfflineCustomerInfoCreatorTests: TestCase {

    func testCreateIfAvailableWithNoFetcherReturnsNil() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: nil,
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                observerMode: false
            )
        ).to(beNil())
    }

    func testCreateIfAvailableInObserverMode() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: MockPurchasedProductsFetcher(),
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                observerMode: true
            )
        ).to(beNil())
    }

    func testCreateIfAvailable() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: MockPurchasedProductsFetcher(),
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                observerMode: false
            )
        ).toNot(beNil())
    }

}
