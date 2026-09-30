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

    func testHasNoCachedSettingsBeforeLoading() {
        expect(self.provider.cachedSettings()).to(beNil())
    }

    func testLoadsAndDeliversSettingsAfterTheInFlightRefreshResolves() async {
        self.manager.committedTopicAfterInFlightRefreshHandler = { _ in ["default": .init()] }
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        await self.provider.loadAndDeliverSettings()

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()) == SDKSettings()
        expect(self.delegate.settings) == SDKSettings()
    }

    func testInvalidatesCachedSettingsWhenGenerationChanges() async {
        await self.provider.loadAndDeliverSettings()

        self.manager.configGeneration += 1

        expect(self.provider.cachedSettings()).to(beNil())
    }

    func testDoesNotNotifyDelegateWhenSettingsHaveNotChanged() async {
        self.provider.delegate = self.delegate

        await self.provider.loadAndDeliverSettings()
        self.manager.configGeneration += 1
        await self.provider.loadAndDeliverSettings()

        expect(self.delegate.invokedDidUpdateCount) == 1
    }

    func testDoesNotCacheOrNotifyBeforeRemoteConfigIsCommitted() async {
        self.manager.stubbedHasCommittedConfig = false
        self.provider.delegate = self.delegate

        await self.provider.loadAndDeliverSettings()

        expect(self.provider.cachedSettings()).to(beNil())
        expect(self.delegate.settings).to(beNil())
    }

    func testConfigLifecycleCommitLoadsAndNotifiesDelegate() async {
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        self.provider.remoteConfigEventReceived(.committed(generation: self.manager.configGeneration))

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()) == SDKSettings()
    }

    func testInitialStateDoesNotLoadSettings() {
        self.provider.remoteConfigEventReceived(.initialState(generation: self.manager.configGeneration))

        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
    }

    func testRepeatedAppStartRefreshCompletionsReloadSettingsWithoutRedeliveringUnchangedSettings() async {
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        self.provider.remoteConfigEventReceived(
            .refreshFinished(fetchContext: .appStart, generation: self.manager.configGeneration)
        )

        await self.fulfillment(of: [expectation], timeout: 1)

        self.provider.remoteConfigEventReceived(
            .refreshFinished(fetchContext: .appStart, generation: self.manager.configGeneration)
        )

        await expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount).toEventually(equal(2))
        await expect(self.delegate.invokedDidUpdateCount).toEventually(equal(1))
    }

}

private final class MockSDKSettingsConfigProviderDelegate: SDKSettingsConfigProviderDelegate {

    var expectation: XCTestExpectation?
    private(set) var invokedDidUpdateCount = 0
    private(set) var settings: SDKSettings?

    func sdkSettingsConfigProviderDidUpdate(_ settings: SDKSettings) {
        self.invokedDidUpdateCount += 1
        self.settings = settings
        self.expectation?.fulfill()
    }

}
