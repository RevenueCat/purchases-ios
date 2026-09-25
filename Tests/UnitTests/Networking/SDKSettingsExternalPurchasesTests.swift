//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKSettingsExternalPurchasesTests.swift
//
//  Created by Antonio Pallares on 24/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class SDKSettingsExternalPurchasesTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: SDKSettingsConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.manager = MockRemoteConfigManager()
        self.provider = SDKSettingsConfigProvider(manager: self.manager)
    }

    /// The backend serves one entry per store, since the store an app buys through is not always the one its
    /// API key points at. Only Apple's has a say here.
    func testReadsTheAppStoreStorefronts() async throws {
        try self.stub(externalPurchases: """
        {
          "app_store": {
            "storefronts_allowed_without_store_eligibility": ["USA", "JPN"]
          },
          "play_store": {
            "storefronts_allowed_without_store_eligibility": ["US"]
          }
        }
        """)

        let storefronts = await self.storefronts()

        expect(storefronts) == ["USA", "JPN"]
    }

    func testUppercasesTheStorefronts() async throws {
        try self.stub(externalPurchases: #"{"app_store": {"storefronts_allowed_without_store_eligibility": ["usa"]}}"#)

        let storefronts = await self.storefronts()

        expect(storefronts) == ["USA"]
    }

    /// Absent from a backend that predates the policy.
    func testReadsNoStorefrontsWithoutExternalPurchases() async throws {
        try self.stub(item: "{}")

        let storefronts = await self.storefronts()

        expect(storefronts).to(beEmpty())
    }

    /// A store the SDK does not buy through says nothing about where it may.
    func testReadsNoStorefrontsWithoutTheAppStoreEntry() async throws {
        try self.stub(externalPurchases: #"{"play_store": {"storefronts_allowed_without_store_eligibility": ["US"]}}"#)

        let storefronts = await self.storefronts()

        expect(storefronts).to(beEmpty())
    }

    func testReadsNoStorefrontsWithoutTheStorefrontsKey() async throws {
        try self.stub(externalPurchases: #"{"app_store": {"token_reporting_enabled": true}}"#)

        let storefronts = await self.storefronts()

        expect(storefronts).to(beEmpty())
    }

    func testReadsAnEmptyListAsAllowingNoStorefront() async throws {
        try self.stub(externalPurchases: #"{"app_store": {"storefronts_allowed_without_store_eligibility": []}}"#)

        let storefronts = await self.storefronts()

        expect(storefronts).to(beEmpty())
    }

    /// Anything unexpected in the policy is never taken as an allowance.
    func testFallsBackToTheDefaultSettingsFromAMalformedPolicy() async throws {
        try self.stub(externalPurchases: """
        {"app_store": {"storefronts_allowed_without_store_eligibility": ["USA", 7]}}
        """)

        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    // MARK: - Helpers

    private func storefronts() async -> Set<String> {
        return await self.provider.settings().externalPurchases.appStore.storefrontsAllowedWithoutStoreEligibility
    }

    private func stub(externalPurchases: String) throws {
        try self.stub(item: #"{"external_purchases": \#(externalPurchases)}"#)
    }

    /// Decodes the item the way the config response is decoded, so the wire keys are exercised rather than
    /// assumed.
    private func stub(item: String) throws {
        self.manager.stubbedTopics[.sdkSettings] = try JSONDecoder.default.decode(
            RemoteConfiguration.ConfigTopic.self,
            from: #"{"default": \#(item)}"#.asData
        )
    }

}
