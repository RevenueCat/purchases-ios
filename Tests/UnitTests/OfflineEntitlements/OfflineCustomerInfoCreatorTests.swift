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

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class OfflineCustomerInfoCreatorTests: TestCase {

    private let mockPurchasedProductsFetcher = MockPurchasedProductsFetcher()
    private let mockProductEntitlementMappingFetcher = MockProductEntitlementMappingFetcher()
    private let mockDiagnosticsTracker = MockDiagnosticsTracker()
    private var creator: OfflineCustomerInfoCreator!

    override func setUp() {
        super.setUp()

        self.creator = .init(purchasedProductsFetcher: self.mockPurchasedProductsFetcher,
                             productEntitlementMappingFetcher: self.mockProductEntitlementMappingFetcher,
                             tracker: self.mockDiagnosticsTracker)
    }

    func testTrackEnteredOfflineEntitlementsModeOnSuccessfulCreation() async throws {
        self.mockProductEntitlementMappingFetcher.stubbedResult = .init(
            entitlementsByProduct: ["product": ["entitlement"]]
        )
        self.mockPurchasedProductsFetcher.stubbedResult = .success([])

        _ = try await self.creator.create(for: "user")
        expect(self.mockDiagnosticsTracker.trackedEnteredOfflineEntitlementsModeCalls.value) == 1
    }

    func testTrackEnteredOfflineEntitlementsModeNotCalledWhenMappingMissing() async throws {
        self.mockProductEntitlementMappingFetcher.stubbedResult = nil
        self.mockPurchasedProductsFetcher.stubbedResult = .success([])

        do {
            _ = try await self.creator.create(for: "user")
            fail("Expected error")
        } catch {
            expect(self.mockDiagnosticsTracker.trackedEnteredOfflineEntitlementsModeCalls.value) == 0
        }
    }

    func testTrackEnteredOfflineEntitlementsModeNotCalledWhenFetcherFails() async throws {
        self.mockProductEntitlementMappingFetcher.stubbedResult = .init(
            entitlementsByProduct: ["product": ["entitlement"]]
        )
        self.mockPurchasedProductsFetcher.stubbedResult = .failure(ErrorCode.invalidAppUserIdError)

        do {
            _ = try await self.creator.create(for: "user")
            fail("Expected error")
        } catch {
            expect(self.mockDiagnosticsTracker.trackedEnteredOfflineEntitlementsModeCalls.value) == 0
        }
    }
}

class CreateOfflineCustomerInfoCreatorTests: TestCase {

    func testCreateIfAvailableWithNoFetcherReturnsNil() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: nil,
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                tracker: nil,
                observerMode: false
            )
        ).to(beNil())
    }

    func testCreateIfAvailableInObserverMode() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: MockPurchasedProductsFetcher(),
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                tracker: nil,
                observerMode: true
            )
        ).to(beNil())
    }

    func testCreateIfAvailable() {
        expect(
            OfflineCustomerInfoCreator.createIfAvailable(
                with: MockPurchasedProductsFetcher(),
                productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
                tracker: nil,
                observerMode: false
            )
        ).toNot(beNil())
    }

}
