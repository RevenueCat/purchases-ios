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

    func testAssemblesUiConfigWhenVariableConfigPartIsMissing() async throws {
        // variableConfig has decode-time defaults, so omitting it entirely must not fail assembly.
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{}"#,
                  variableConfig: nil, customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).toNot(beNil())
    }

    func testAssemblesUiConfigWhenCustomVariablesPartIsMissing() async throws {
        // customVariables has decode-time defaults, so omitting it entirely must not fail assembly.
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{}"#,
                  variableConfig: nil, customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).toNot(beNil())
        expect(uiConfig?.customVariables).to(beEmpty())
    }

    func testMalformedVariableConfigFallsBackToDefaultInsteadOfFailingTheWholeAssembly() async throws {
        // variable_config is syntactically valid JSON but the wrong shape for VariableConfig, which used
        // to fail the single merged decode of the whole UIConfig, discarding good app/localizations data.
        self.stub(app: #"{"colors": {}, "fonts": {}}"#, localizations: #"{"en_US": {"day": "Day"}}"#,
                  variableConfig: #"{"variable_compatibility_map": "not-a-dictionary"}"#, customVariables: nil)

        let uiConfig = await self.provider.getUiConfig()

        expect(uiConfig).toNot(beNil())
        expect(uiConfig?.localizations["en_US"]?["day"]) == "Day"
        expect(uiConfig?.variableConfig.variableCompatibilityMap).to(beEmpty())
        self.logger.verifyMessageWasLogged("Failed to decode ui_config part 'variable_config'", level: .error)
    }

    func testLogsWarningWhenARequiredPartIsMissing() async throws {
        self.stub(app: nil, localizations: #"{}"#, variableConfig: nil, customVariables: nil)

        _ = await self.provider.getUiConfig()

        self.logger.verifyMessageWasLogged(Strings.remoteConfig.uiConfigMissingRequiredPart, level: .warn)
    }

    func testRequestsWireItemKeysNotCamelCased() async throws {
        _ = await self.provider.getUiConfig()

        let requestedKeys = self.mockManager.invokedBlobDataParameters
            .filter { $0.topic == .uiConfig }
            .map(\.itemKey)
        expect(requestedKeys).to(contain(["app", "localizations", "variable_config", "custom_variables"]))
    }

    private func stub(app: String?, localizations: String?, variableConfig: String?, customVariables: String?) {
        var data: [String: Data] = [:]
        if let app { data["app"] = Data(app.utf8) }
        if let localizations { data["localizations"] = Data(localizations.utf8) }
        if let variableConfig { data["variable_config"] = Data(variableConfig.utf8) }
        if let customVariables { data["custom_variables"] = Data(customVariables.utf8) }
        self.mockManager.stubbedBlobData[.uiConfig] = data
    }

}
