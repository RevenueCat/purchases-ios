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

    func testCachesDecodedUiConfigAndSkipsBlobMergeOnUnchangedGenerationAndTopic() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )

        let first = await self.provider.getUiConfig()
        let mergesAfterFirst = self.mockManager.invokedMergeItemsBlobDataParameters.count
        let second = await self.provider.getUiConfig()

        expect(first).toNot(beNil())
        expect(second?.localizations["en_US"]?["day"]) == "Day"
        expect(mergesAfterFirst) == 1
        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == mergesAfterFirst
        expect(self.provider.cachedUiConfig()?.localizations["en_US"]?["day"]) == "Day"
    }

    func testReDecodesWhenUiConfigGenerationChanges() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        _ = await self.provider.getUiConfig()
        self.mockManager.configGeneration += 1

        _ = await self.provider.getUiConfig()

        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 2
        expect(self.provider.cachedUiConfig()).toNot(beNil())
    }

    func testStoresUiConfigWhenGenerationChangesDuringInitialTopicRead() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        self.mockManager.shouldStoreTopicCompletion = true
        let topic = try XCTUnwrap(self.mockManager.stubbedTopics[.uiConfig])

        async let uiConfig = self.provider.getUiConfig()
        await self.waitUntilTopicRequested()
        self.mockManager.configGeneration += 1
        self.mockManager.completeStoredTopic(with: topic)

        let resolvedUiConfig = await uiConfig
        expect(resolvedUiConfig).toNot(beNil())
        expect(self.provider.cachedUiConfig()).toNot(beNil())
    }

    func testReturnsNilAndDoesNotCacheUiConfigWhenGenerationChangesDuringDecode() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        self.mockManager.shouldStoreBlobDataCompletion = true

        async let uiConfig = self.provider.getUiConfig()
        await self.waitUntilBlobDataRequested()
        self.mockManager.configGeneration += 1
        self.mockManager.completeStoredBlobReads()

        let resolvedUiConfig = await uiConfig
        expect(resolvedUiConfig).to(beNil())
        expect(self.provider.cachedUiConfig()).to(beNil())
    }

    func testCachedUiConfigReturnsNilWhenGenerationChangesWithoutRewarming() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        _ = await self.provider.getUiConfig()

        self.mockManager.configGeneration += 1

        expect(self.provider.cachedUiConfig()).to(beNil())
    }

    func testReDecodesWhenUiConfigTopicChanges() async throws {
        self.stub(
            app: #"{"colors": {}, "fonts": {}}"#,
            localizations: #"{"en_US": {"day": "Day"}}"#,
            variableConfig: #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#,
            customVariables: #"{}"#
        )
        _ = await self.provider.getUiConfig()
        self.mockManager.stubbedTopics[.uiConfig]?["app"] = .init(blobRef: "app-v2")

        _ = await self.provider.getUiConfig()

        expect(self.mockManager.invokedMergeItemsBlobDataParameters.count) == 2
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

    func testRequestsMergedBlobDataForWireItemKeysNotCamelCased() async throws {
        self.mockManager.stubbedTopics[.uiConfig] = [
            "app": .init(),
            "localizations": .init(),
            "variable_config": .init(),
            "custom_variables": .init()
        ]

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

    private func waitUntilTopicRequested() async {
        while self.mockManager.invokedTopicCount == 0 {
            await Task.yield()
        }
    }

    private func waitUntilBlobDataRequested() async {
        while self.mockManager.invokedBlobDataParameters.isEmpty {
            await Task.yield()
        }
    }

}
