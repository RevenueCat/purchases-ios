//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchasesConfigProviderTests.swift
//
//  Created by Antonio Pallares on 21/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ExternalPurchasesConfigProviderTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: ExternalPurchasesConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.manager = MockRemoteConfigManager()
        self.provider = ExternalPurchasesConfigProvider(manager: self.manager)
    }

    func testReadsTheTopicTheBackendServes() {
        expect(RemoteConfigTopic.externalPurchases.wireName) == "external_purchases"
    }

    /// The backend serves every store's list to every app, since the store an app buys through is not always
    /// the one its API key points at. Only Apple's has a say here.
    func testReadsTheAppStoreStorefronts() async throws {
        try self.stub(topic: """
        {
          "storefront_policy": {
            "allowed_without_store_eligibility": {
              "app_store": ["USA", "JPN"],
              "play_store": ["US"]
            }
          }
        }
        """)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts) == ["USA", "JPN"]
    }

    /// Storefronts are compared against what StoreKit reports, so they are held in one case rather than
    /// trusted to arrive in it.
    func testUppercasesTheStorefronts() async throws {
        try self.stub(topic: #"{"storefront_policy": {"allowed_without_store_eligibility": {"app_store": ["usa"]}}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts) == ["USA"]
    }

    /// A rollout that has not reached this app yet reads differently from a policy that deliberately allows
    /// no storefront, since one is worth chasing and the other is not.
    func testReadsNoStorefrontsWithoutATopic() async {
        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        expect(self.manager.invokedTopicCount) == 1
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyUnavailable)
    }

    func testReadsNoStorefrontsWithoutThePolicyItem() async throws {
        try self.stub(topic: #"{"another_item": {"allowed_without_store_eligibility": {"app_store": ["USA"]}}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
    }

    /// A store the SDK does not buy through says nothing about where it may.
    func testReadsNoStorefrontsWithoutAnAppStoreList() async throws {
        try self.stub(topic: #"{"storefront_policy": {"allowed_without_store_eligibility": {"play_store": ["US"]}}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts)
    }

    /// The policy is part of a wire contract shared with the other SDKs, so anything unexpected in it is
    /// skipped rather than taken as an allowance.
    func testSkipsStorefrontsThatAreNotCountryCodes() async throws {
        try self.stub(topic: """
        {"storefront_policy": {"allowed_without_store_eligibility": {"app_store": ["USA", 7, null, ["JPN"]]}}}
        """)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts) == ["USA"]
    }

    func testReadsNoStorefrontsFromAMalformedPolicy() async throws {
        try self.stub(topic: #"{"storefront_policy": {"allowed_without_store_eligibility": "USA"}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
    }

    /// An empty list is the answer of a backend that allows the purchase nowhere, not of one that has not
    /// answered.
    func testReadsAnEmptyListAsAllowingNoStorefront() async throws {
        try self.stub(topic: #"{"storefront_policy": {"allowed_without_store_eligibility": {"app_store": []}}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        self.logger.verifyMessageWasNotLogged(Strings.remoteConfig.externalPurchasesPolicyUnavailable,
                                              allowNoMessages: true)
        self.logger.verifyMessageWasNotLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts,
                                              allowNoMessages: true)
    }

    // MARK: - Helpers

    /// Decodes the topic the way the config response is decoded, so the wire keys are exercised rather than
    /// assumed.
    private func stub(topic: String) throws {
        self.manager.stubbedTopics[.externalPurchases] = try JSONDecoder.default.decode(
            RemoteConfiguration.ConfigTopic.self,
            from: topic.asData
        )
    }

}
