//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowScreenMapperTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowScreenMapperTests: TestCase {

    func testMapsPaywallComponentsDataFieldsFromScreen() throws {
        let screen = try Self.makeScreen(
            offeringId: "offering_a",
            templateName: "componentsTest",
            assetBaseURL: "https://assets.pawwalls.com",
            revision: 7,
            defaultLocale: "en_US"
        )
        let uiConfig = try Self.makeUIConfig()

        let result = WorkflowScreenMapper.toPaywallComponents(screen: screen, uiConfig: uiConfig)

        expect(result.data.templateName) == "componentsTest"
        expect(result.data.assetBaseURL) == URL(string: "https://assets.pawwalls.com")
        expect(result.data.revision) == 7
        expect(result.data.defaultLocale) == "en_US"
    }

    func testPassesThroughUiConfig() throws {
        let screen = try Self.makeScreen()
        let uiConfig = try Self.makeUIConfig()

        let result = WorkflowScreenMapper.toPaywallComponents(screen: screen, uiConfig: uiConfig)

        expect(result.uiConfig) == uiConfig
    }

    func testPassesThroughComponentsConfig() throws {
        let screen = try Self.makeScreen()
        let uiConfig = try Self.makeUIConfig()

        let result = WorkflowScreenMapper.toPaywallComponents(screen: screen, uiConfig: uiConfig)

        expect(result.data.componentsConfig) == screen.componentsConfig
    }

    func testPassesThroughComponentsLocalizations() throws {
        let screen = try Self.makeScreen()
        let uiConfig = try Self.makeUIConfig()

        let result = WorkflowScreenMapper.toPaywallComponents(screen: screen, uiConfig: uiConfig)

        expect(result.data.componentsLocalizations) == screen.componentsLocalizations
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowScreenMapperTests {

    static func makeScreen(
        offeringId: String = "offering_a",
        templateName: String = "componentsTest",
        assetBaseURL: String = "https://assets.pawwalls.com",
        revision: Int = 3,
        defaultLocale: String = "en_US"
    ) throws -> WorkflowResponse.WorkflowScreen {
        let json = """
        {
            "offering_id": "\(offeringId)",
            "template_name": "\(templateName)",
            "asset_base_url": "\(assetBaseURL)",
            "revision": \(revision),
            "default_locale": "\(defaultLocale)",
            "components_localizations": {},
            "components_config": {
                "base": {
                    "stack": {
                        "type": "stack",
                        "components": [],
                        "dimension": {
                            "type": "vertical",
                            "alignment": "center",
                            "distribution": "center"
                        },
                        "size": {
                            "width": { "type": "fill" },
                            "height": { "type": "fill" }
                        },
                        "margin": {},
                        "padding": {},
                        "spacing": 0
                    },
                    "background": {
                        "type": "color",
                        "value": {
                            "light": { "type": "hex", "value": "#220000ff" }
                        }
                    }
                }
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorkflowResponse.WorkflowScreen.self, from: data)
    }

    static func makeUIConfig() throws -> UIConfig {
        let json = """
        {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UIConfig.self, from: data)
    }

}

#endif
