//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewConfigurationTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallViewConfigurationTests: TestCase {

    func testCachedInitialOfferingReturnsProvidedOfferingForOfferingContent() {
        let handler = Self.createPurchaseHandler()
        let offering = TestData.offeringWithNoIntroOffer

        let result = handler.cachedInitialOffering(for: .offering(offering))

        expect(result) === offering
    }

    func testResolveOfferingOrThrowReturnsProvidedOfferingForOfferingContent() async throws {
        let handler = Self.createPurchaseHandler()
        let offering = TestData.offeringWithNoIntroOffer

        let result = try await handler.resolveOfferingOrThrow(for: .offering(offering))

        expect(result) === offering
    }

    func testOfferingIdentifierCachedInitialOfferingDependsOnWorkflowResolutionMode() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(cachedOffering)

        let result = handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil)
        )

        #if ENABLE_WORKFLOWS_ENDPOINT
        expect(result).to(beNil())
        #else
        expect(result?.identifier) == cachedOffering.identifier
        #endif
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewConfigurationTests {

    static func createPurchaseHandler(purchases: MockPurchases = createMockPurchases()) -> PurchaseHandler {
        return PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases)
        )
    }

    static func createMockPurchases() -> MockPurchases {
        return MockPurchases { _, _, _ in
            (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        } restorePurchases: {
            TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            TestData.customerInfo
        }
    }

    static func createOfferings(_ offering: Offering) -> Offerings {
        return Offerings(
            offerings: [offering.identifier: offering],
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )
    }

}
