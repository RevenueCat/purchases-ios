//
//  SDKSettingsConfigProviderTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class SDKSettingsConfigProviderTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: SDKSettingsConfigProvider!
    private var delegate: MockSDKSettingsConfigProviderDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.manager = MockRemoteConfigManager()
        self.provider = SDKSettingsConfigProvider(manager: self.manager)
        self.delegate = MockSDKSettingsConfigProviderDelegate()
    }

    /// Pinned as a literal so the SDK cannot silently diverge from the backend topic name.
    func testTopicWireNameMatchesTheBackend() {
        expect(RemoteConfigTopic.sdkSettings.wireName) == "sdk_settings"
    }

    func testDecodesTheEmptyDefaultSettings() async {
        self.manager.stubbedTopics[.sdkSettings] = ["default": .init()]

        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    func testIgnoresUnknownSettingsForForwardCompatibility() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["future_setting": true])
        ]

        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    func testReturnsDefaultSettingsWhenTheTopicIsAbsent() async {
        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    func testReturnsDefaultSettingsWhenTheDefaultItemIsAbsent() async {
        self.manager.stubbedTopics[.sdkSettings] = [:]

        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    func testHasNoCachedSettingsBeforeRefresh() {
        expect(self.provider.cachedSettings()).to(beNil())
    }

    func testCachesSettingsBeforeNotifyingDelegateWhenRefreshed() async {
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        await self.provider.refresh()

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()) == SDKSettings()
        expect(self.delegate.settings) == SDKSettings()
    }

    func testInvalidatesCachedSettingsWhenGenerationChanges() async {
        await self.provider.refresh()

        self.manager.configGeneration += 1

        expect(self.provider.cachedSettings()).to(beNil())
    }

    func testDoesNotCacheOrNotifyBeforeRemoteConfigIsCommitted() async {
        self.manager.stubbedHasCommittedConfig = false
        self.provider.delegate = self.delegate

        await self.provider.refresh()

        expect(self.provider.cachedSettings()).to(beNil())
        expect(self.delegate.settings).to(beNil())
    }

    func testStateObserverRefreshesAndNotifiesDelegate() async {
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        self.provider.remoteConfigStateDidChange(generation: self.manager.configGeneration)

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()) == SDKSettings()
    }

}

private final class MockSDKSettingsConfigProviderDelegate: SDKSettingsConfigProviderDelegate {

    var expectation: XCTestExpectation?
    private(set) var settings: SDKSettings?

    func sdkSettingsConfigProviderDidUpdate(_ provider: SDKSettingsConfigProviderType) async {
        self.settings = provider.cachedSettings()
        self.expectation?.fulfill()
    }

}
