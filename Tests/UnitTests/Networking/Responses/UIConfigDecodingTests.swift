//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfigDecodingTests.swift
//
//  Created by Josh Holtz on 12/31/24.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class UIConfigDecodingTests: BaseHTTPResponseTest {

    func testDecodesPaywallData() throws {
        let uiConfig: UIConfig = try Self.decodeFixture("UIConfig")

        expect(uiConfig.app.colors).to(equal([
            "primary": .init(light: .hex("#ffcc00")),
            "secondary": .init(light: .linear(45, [
                .init(color: "#032400ff", percent: 0),
                .init(color: "#090979ff", percent: 35),
                .init(color: "#216c32ff", percent: 100)
            ])),
            "tertiary": .init(light: .radial([
                .init(color: "#032400ff", percent: 0),
                .init(color: "#090979ff", percent: 35),
                .init(color: "#216c32ff", percent: 100)
            ]))
        ]))
        expect(uiConfig.app.fonts).to(equal([
            "primary": .init(ios: UIConfig.FontInfo(name: "SF Pro"))
        ]))

        expect(uiConfig.localizations).to(equal([
            "en_US": [
                "monthly": "monthly"
            ],
            "es_ES": [
                "monthly": "mensual"
            ]
        ]))

        expect(uiConfig.variableConfig.variableCompatibilityMap).to(equal([
            "new var": "guaranteed var"
        ]))
        expect(uiConfig.variableConfig.functionCompatibilityMap).to(equal([
            "new fun": "guaranteed fun"
        ]))
    }

    func testDecodesCustomVariables() throws {
        let json = """
        {
            "app": {
                "colors": {},
                "fonts": {}
            },
            "localizations": {},
            "variable_config": {
                "variable_compatibility_map": {},
                "function_compatibility_map": {}
            },
            "custom_variables": {
                "player_name": {
                    "type": "string",
                    "default_value": "Player"
                },
                "max_health": {
                    "type": "number",
                    "default_value": "100"
                },
                "is_premium": {
                    "type": "boolean",
                    "default_value": "false"
                }
            }
        }
        """

        let uiConfig: UIConfig = try JSONDecoder.default.decode(
            UIConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(uiConfig.customVariables.count).to(equal(3))

        expect(uiConfig.customVariables["player_name"]?.type).to(equal("string"))
        expect(uiConfig.customVariables["player_name"]?.defaultValue).to(equal("Player"))

        expect(uiConfig.customVariables["max_health"]?.type).to(equal("number"))
        expect(uiConfig.customVariables["max_health"]?.defaultValue).to(equal("100"))

        expect(uiConfig.customVariables["is_premium"]?.type).to(equal("boolean"))
        expect(uiConfig.customVariables["is_premium"]?.defaultValue).to(equal("false"))
    }

    func testDecodesWithoutCustomVariables() throws {
        let json = """
        {
            "app": {
                "colors": {},
                "fonts": {}
            },
            "localizations": {},
            "variable_config": {
                "variable_compatibility_map": {},
                "function_compatibility_map": {}
            }
        }
        """

        let uiConfig: UIConfig = try JSONDecoder.default.decode(
            UIConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(uiConfig.customVariables).to(beEmpty())
    }

}

#endif
