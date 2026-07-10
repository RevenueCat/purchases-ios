//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UiConfigProviderTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class UiConfigProviderTests: TestCase {

    private var mockManager: MockRemoteConfigManager!
    private var provider: UiConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockManager = MockRemoteConfigManager()
        self.provider = UiConfigProvider(manager: self.mockManager)
    }

#if !os(tvOS) // For Paywalls V2

    func testAssemblesUiConfigFromItsFourParts() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{"user_name": {"type": "string", "default_value": "Friend"}}"#
        )

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).toNot(beNil())
        expect(uiConfig?.localizations["en_US"]?["day"]) == "Day"
        expect(uiConfig?.customVariables["user_name"]?.type) == "string"
        expect(uiConfig?.customVariables["user_name"]?.defaultValue) == "Friend"
    }

    func testReturnsNilWhenAppPartIsMissing() async throws {
        self.stub(app: nil, localizations: #"{}"#, variableConfig: nil, customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
    }

    func testReturnsNilWhenLocalizationsPartIsMissing() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: nil, variableConfig: nil, customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
    }

    func testReturnsNilWhenVariableConfigPartIsMissing() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{}"#,
                  variableConfig: nil, customVariables: #"{}"#)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
    }

    func testReturnsNilWhenCustomVariablesPartIsMissing() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{}"#,
                  variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
                  customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
    }

    func testMalformedVariableConfigReturnsNil() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{"en_US": {"day": "Day"}}"#,
                  variableConfig: #"{"variable_compatibility_map": "not-a-dictionary"}"#,
                  customVariables: #"{}"#)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
        self.logger.verifyMessageWasLogged(
            "Failed to decode merged ui_config",
            level: .error
        )
    }

    func testMalformedCustomVariablesReturnsNil() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{"en_US": {"day": "Day"}}"#,
                  variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
                  customVariables: #"{"user_name": "not-a-definition"}"#)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
        self.logger.verifyMessageWasLogged(
            "Failed to decode merged ui_config",
            level: .error
        )
    }

    func testNullCustomVariablesReturnsUiConfigWithEmptyCustomVariables() async throws {
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{"en_US": {"day": "Day"}}"#,
                  variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
                  customVariables: #"null"#)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).toNot(beNil())
        expect(uiConfig?.customVariables).to(beEmpty())
    }

    func testLogsWarningWhenARequiredPartIsMissing() async throws {
        self.stub(app: nil, localizations: #"{}"#, variableConfig: nil, customVariables: nil)

        _ = await self.provider.getUiConfig()

        self.logger.verifyMessageWasLogged(Strings.remoteConfig.uiConfigMissingRequiredPart, level: .warn)
    }

    func testDoesNotLogMissingPartsWarningWhenRemoteConfigIsDisabled() async throws {
        self.mockManager.isDisabled = true

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
        self.logger.verifyMessageWasNotLogged(
            Strings.remoteConfig.uiConfigMissingRequiredPart,
            level: .warn,
            allowNoMessages: true
        )
    }

    func testCachesDecodedUiConfigAndSkipsDiskWorkOnUnchangedTopic() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )

        let first = await self.provider.getUiConfig()
        let mergesAfterFirst = self.mockManager.invokedMergeItemsBlobDataParameters.count
        expect(first).toNot(beNil())
        expect(mergesAfterFirst) == 1

        let second = await self.provider.getUiConfig()

        // The unchanged `ui_config` topic serves the decoded value from memory: no extra decode.
        expect(second?.localizations["en_US"]?["day"]) == "Day"
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == mergesAfterFirst
    }

    func testDoesNotCacheWhenTopicChangesDuringAssembly() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        // The cache-key read sees topic A, the post-assembly re-read sees topic B: a refresh
        // landed mid-decode, so the value must NOT be memoized under A.
        let topicA: RemoteConfiguration.ConfigTopic = ["app": .init(blobRef: "app-a", prefetch: false, content: [:])]
        let topicB: RemoteConfiguration.ConfigTopic = ["app": .init(blobRef: "app-b", prefetch: false, content: [:])]
        self.mockManager.stubbedTopicSequence = [topicA, topicB]

        _ = await self.provider.getUiConfig()
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 1

        // Sequence exhausted; topic() now returns the stubbed topic (A). Nothing was cached
        // under A, so this re-decodes rather than serving a value assembled during the race.
        self.mockManager.stubbedTopics[.uiConfig] = topicA
        _ = await self.provider.getUiConfig()
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 2
    }

    func testDoesNotServeStaleUiConfigAfterTopicBecomesNil() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        let cached = await self.provider.getUiConfig()
        expect(cached).toNot(beNil())

        // Simulate an identity-bound clear: the committed topic and its blobs are gone. The
        // cached value keyed on the old topic must not be served.
        self.mockManager.stubbedTopics[.uiConfig] = nil
        self.mockManager.stubbedBlobData[.uiConfig] = [:]

        let afterClear = await self.provider.getUiConfig()

        expect(afterClear).to(beNil())
    }

    func testReDecodesWhenUiConfigTopicChanges() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        _ = await self.provider.getUiConfig()
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 1

        // A new revision changes the topic (content-addressed blob refs move), which must
        // invalidate the cached value and force a re-decode.
        self.mockManager.stubbedTopics[.uiConfig] = [
            "app": .init(blobRef: "app-v2", prefetch: false, content: [:]),
            "localizations": .init(blobRef: "localizations-v2", prefetch: false, content: [:])
        ]
        _ = await self.provider.getUiConfig()

        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 2
    }

    func testRequestsMergedBlobDataForWireItemKeysNotCamelCased() async throws {
        _ = await self.provider.getUiConfig()

        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 1
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.first?.topic) == .uiConfig
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.first?.itemKeys) == [
            "app",
            "localizations",
            "variable_config",
            "custom_variables"
        ]
    }

#else

    func testAssemblesUiConfigWhenRequiredPartsArePresent() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: nil,
            customVariables: nil
        )

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig) == .empty
    }

    func testDoesNotLogMissingPartsWarningWhenRemoteConfigIsDisabled() async throws {
        self.mockManager.isDisabled = true

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).to(beNil())
        self.logger.verifyMessageWasNotLogged(
            Strings.remoteConfig.uiConfigMissingRequiredPart,
            level: .warn,
            allowNoMessages: true
        )
    }

#endif

    private func stub(app: String?, localizations: String?, variableConfig: String?, customVariables: String?) {
        var data: [String: Data] = [:]
        if let app { data["app"] = Data(app.utf8) }
        if let localizations { data["localizations"] = Data(localizations.utf8) }
        if let variableConfig { data["variable_config"] = Data(variableConfig.utf8) }
        if let customVariables { data["custom_variables"] = Data(customVariables.utf8) }
        self.mockManager.stubbedBlobData[.uiConfig] = data
        self.mockManager.stubbedTopics[.uiConfig] = data.keys.reduce(into: [:]) { topic, key in
            topic[key] = RemoteConfiguration.ConfigItem()
        }
    }

}
