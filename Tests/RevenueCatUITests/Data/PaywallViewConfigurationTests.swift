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

    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()

        Purchases.clearSingleton()

        let suiteName = "PaywallViewConfigurationTests.\(UUID().uuidString)"
        self.userDefaultsSuiteName = suiteName
        self.userDefaults = UserDefaults(suiteName: suiteName)
        self.userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        Purchases.clearSingleton()

        if let suiteName = self.userDefaultsSuiteName {
            self.userDefaults.removePersistentDomain(forName: suiteName)
        }

        self.userDefaults = nil
        self.userDefaultsSuiteName = nil

        super.tearDown()
    }

    func testCachedInitialOfferingReturnsProvidedOfferingForOfferingContent() {
        let offering = TestData.offeringWithNoIntroOffer

        let result = PaywallViewConfiguration.Content
            .offering(offering)
            .cachedInitialOffering()

        expect(result) === offering
    }

    func testResolveOfferingOrThrowReturnsProvidedOfferingForOfferingContent() async throws {
        let offering = TestData.offeringWithNoIntroOffer

        let result = try await PaywallViewConfiguration.Content
            .offering(offering)
            .resolveOfferingOrThrow()

        expect(result) === offering
    }

    func testOfferingIdentifierCachedInitialOfferingDependsOnWorkflowResolutionMode() throws {
        let purchases = Purchases.configure(
            with: Configuration.Builder(withAPIKey: "api_key")
                .with(userDefaults: self.userDefaults)
                .with(dangerousSettings: DangerousSettings(uiPreviewMode: true))
                .build()
        )
        let deviceCache = try XCTUnwrap(Self.deviceCache(from: purchases))
        let cachedOffering = TestData.offeringWithNoIntroOffer

        deviceCache.cacheInMemory(offerings: Self.createOfferings(cachedOffering))

        let result = PaywallViewConfiguration.Content
            .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil)
            .cachedInitialOffering()

        #if ENABLE_WORKFLOWS_ENDPOINT
        expect(result).to(beNil())
        #else
        expect(result?.identifier) == cachedOffering.identifier
        #endif
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewConfigurationTests {

    static func deviceCache(from purchases: Purchases) -> DeviceCache? {
        return Mirror(reflecting: purchases).descendant("deviceCache") as? DeviceCache
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
