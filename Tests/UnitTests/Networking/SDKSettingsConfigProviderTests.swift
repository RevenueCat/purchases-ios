//
//  SDKSettingsConfigProviderTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
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
        expect(settings.diagnostics).to(beNil())
    }

    func testDecodesDiagnosticsEnabled() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]

        let settings = await self.provider.settings()

        expect(settings.diagnostics?.enabled) == true
    }

    func testDecodesDiagnosticsDisabled() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": false]])
        ]

        let settings = await self.provider.settings()

        expect(settings.diagnostics?.enabled) == false
    }

    func testDecodesDiagnosticsWithoutAnEnabledValue() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": [:]])
        ]

        let settings = await self.provider.settings()

        expect(settings.diagnostics?.enabled).to(beNil())
    }

    func testReturnsDefaultSettingsWhenDiagnosticsEnabledIsMalformed() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": "true"]])
        ]

        let settings = await self.provider.settings()

        expect(settings) == SDKSettings()
    }

    func testDecodingMalformedDiagnosticsEnabledDefaultsOnlyDiagnostics() throws {
        let data = Data(#"{"diagnostics":{"enabled":"true"}}"#.utf8)

        let settings = try JSONDecoder.default.decode(SDKSettings.self, from: data)

        expect(settings) == SDKSettings()
    }

    func testDecodingMalformedDiagnosticsDefaultsOnlyDiagnostics() throws {
        let data = Data(#"{"diagnostics":"enabled"}"#.utf8)

        let settings = try JSONDecoder.default.decode(SDKSettings.self, from: data)

        expect(settings) == SDKSettings()
    }

    func testIgnoresUnknownSettingsForForwardCompatibility() async {
        self.manager.stubbedTopics[.sdkSettings] = ["default": .init(content: ["future_setting": true])]

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
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": false]])
        ]
        self.manager.committedTopicAfterInFlightRefreshHandler = { _ in
            ["default": .init(content: ["diagnostics": ["enabled": true]])]
        }
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        await self.provider.readAndDeliverSettings()

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.delegate.settings?.diagnostics?.enabled) == true
    }

    func testCachesSettingsBeforeNotifyingDelegateWhenLoaded() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation

        self.provider.delegate = self.delegate
        await self.provider.readAndDeliverSettings()

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()?.diagnostics?.enabled) == true
        expect(self.delegate.settings?.diagnostics?.enabled) == true
    }

    func testDoesNotNotifyDelegateWhenSettingsDoNotChange() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        let expectation = self.expectation(description: "initial settings update")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        await self.provider.readAndDeliverSettings()
        await self.fulfillment(of: [expectation], timeout: 1)

        self.manager.configGeneration += 1
        await self.provider.readAndDeliverSettings()

        expect(self.delegate.updateCount) == 1
    }

    func testInvalidatesCachedSettingsWhenGenerationChanges() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        await self.provider.readAndDeliverSettings()

        self.manager.configGeneration += 1

        expect(self.provider.cachedSettings()).to(beNil())
    }

    func testDoesNotCacheOrNotifyBeforeRemoteConfigIsCommitted() async {
        self.manager.stubbedHasCommittedConfig = false
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        self.provider.delegate = self.delegate

        await self.provider.readAndDeliverSettings()

        expect(self.provider.cachedSettings()).to(beNil())
        expect(self.delegate.settings).to(beNil())
    }

    func testConfigLifecycleCommitLoadsAndNotifiesDelegate() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        let expectation = self.expectation(description: "settings updated")
        self.delegate.expectation = expectation
        self.provider.delegate = self.delegate

        self.provider.remoteConfigEventReceived(.committed(generation: self.manager.configGeneration))

        await self.fulfillment(of: [expectation], timeout: 1)
        expect(self.provider.cachedSettings()?.diagnostics?.enabled) == true
    }

    func testObserverRegistrationDoesNotWaitForAnInFlightRefresh() {
        self.provider.remoteConfigEventReceived(.observerRegistered(generation: self.manager.configGeneration))

        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
    }

    func testObserverRegistrationWarmsCachedSettingsWithoutNotifyingDelegate() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
        self.provider.delegate = self.delegate

        self.provider.remoteConfigEventReceived(.observerRegistered(generation: self.manager.configGeneration))

        await expect(self.provider.cachedSettings()?.diagnostics?.enabled).toEventually(equal(true))
        expect(self.delegate.settings).to(beNil())
    }

    func testRepeatedAppStartRefreshCompletionsReloadSettingsWithoutRedeliveringUnchangedSettings() async {
        self.manager.stubbedTopics[.sdkSettings] = [
            "default": .init(content: ["diagnostics": ["enabled": true]])
        ]
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
        await expect(self.delegate.updateCount).toEventually(equal(1))
    }

}

private final class MockSDKSettingsConfigProviderDelegate: SDKSettingsConfigProviderDelegate {

    var expectation: XCTestExpectation?
    private(set) var settings: SDKSettings?
    private(set) var updateCount = 0

    func sdkSettingsConfigProviderDidUpdate(_ settings: SDKSettings) {
        self.settings = settings
        self.updateCount += 1
        self.expectation?.fulfill()
    }

}
