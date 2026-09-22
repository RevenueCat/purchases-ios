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

    /// The backend serves one item per store, since the store an app buys through is not always the one its
    /// API key points at. Only Apple's has a say here.
    func testReadsTheAppStoreStorefronts() async throws {
        try self.stub(topic: """
        {
          "app_store": {
            "storefronts_allowed_without_store_eligibility": ["USA", "JPN"]
          },
          "play_store": {
            "storefronts_allowed_without_store_eligibility": ["US"]
          }
        }
        """)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts) == ["USA", "JPN"]
    }

    /// Storefronts are compared against what StoreKit reports, so they are held in one case rather than
    /// trusted to arrive in it.
    func testUppercasesTheStorefronts() async throws {
        try self.stub(topic: #"{"app_store": {"storefronts_allowed_without_store_eligibility": ["usa"]}}"#)

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

    /// A store the SDK does not buy through says nothing about where it may.
    func testReadsNoStorefrontsWithoutTheAppStoreItem() async throws {
        try self.stub(topic: #"{"play_store": {"storefronts_allowed_without_store_eligibility": ["US"]}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts)
    }

    func testReadsNoStorefrontsWithoutTheStorefrontsKey() async throws {
        try self.stub(topic: #"{"app_store": {"token_reporting_enabled": true}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts)
    }

    /// The policy is part of a wire contract shared with the other SDKs, so anything unexpected in it is
    /// skipped rather than taken as an allowance.
    func testSkipsStorefrontsThatAreNotCountryCodes() async throws {
        try self.stub(topic: """
        {"app_store": {"storefronts_allowed_without_store_eligibility": ["USA", 7, null, ["JPN"]]}}
        """)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts) == ["USA"]
    }

    func testReadsNoStorefrontsFromAMalformedPolicy() async throws {
        try self.stub(topic: #"{"app_store": {"storefronts_allowed_without_store_eligibility": "USA"}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
    }

    /// An empty list is the answer of a backend that allows the purchase nowhere, not of one that has not
    /// answered.
    func testReadsAnEmptyListAsAllowingNoStorefront() async throws {
        try self.stub(topic: #"{"app_store": {"storefronts_allowed_without_store_eligibility": []}}"#)

        let storefronts = await self.provider.storefrontsAllowedWithoutStoreEligibility()

        expect(storefronts).to(beEmpty())
        self.logger.verifyMessageWasNotLogged(Strings.remoteConfig.externalPurchasesPolicyUnavailable,
                                              allowNoMessages: true)
        self.logger.verifyMessageWasNotLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts,
                                              allowNoMessages: true)
    }

    // MARK: - Token reporting

    func testReadsTheTokenReportingToggle() async throws {
        try self.stub(topic: #"{"app_store": {"token_reporting_enabled": true}}"#)

        let reportsTokens = await self.provider.reportsTokensToTheAppStore()

        expect(reportsTokens) == true
    }

    /// A token obliges a report to Apple, so an app only mints one where the backend says it does.
    func testReportsNoTokensWithoutATopic() async {
        let reportsTokens = await self.provider.reportsTokensToTheAppStore()

        expect(reportsTokens) == false
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyUnavailable)
    }

    func testReportsNoTokensWithoutTheToggle() async throws {
        try self.stub(topic: #"{"app_store": {"storefronts_allowed_without_store_eligibility": ["USA"]}}"#)

        let reportsTokens = await self.provider.reportsTokensToTheAppStore()

        expect(reportsTokens) == false
        self.logger.verifyMessageWasLogged(Strings.remoteConfig.externalPurchasesPolicyWithoutTokenReporting)
    }

    /// The toggle is part of a wire contract shared with the other SDKs, so anything that is not the boolean
    /// it should be reads as no report rather than as an obligation.
    func testReportsNoTokensFromAMalformedToggle() async throws {
        try self.stub(topic: #"{"app_store": {"token_reporting_enabled": "true"}}"#)

        let reportsTokens = await self.provider.reportsTokensToTheAppStore()

        expect(reportsTokens) == false
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
