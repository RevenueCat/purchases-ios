//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ComponentOverrideRawPropertiesTests: TestCase {

    typealias IconOverride = PaywallComponent.ComponentOverride<PaywallComponent.PartialIconComponent>

    func testRawPropertiesPreserveKnownIconCodingKeys() throws {
        let override = try Self.decodeIconOverride(
            properties: """
            {
                "icon_name": "star",
                "formats": {
                    "svg": "icon.svg",
                    "png": "icon.png",
                    "heic": "icon.heic",
                    "webp": "icon.webp"
                },
                "color": { "light": { "type": "hex", "value": "#FFFFFF" } }
            }
            """
        )

        XCTAssertEqual(
            Set(override.rawProperties.keys),
            Set([
                PaywallComponent.PartialIconComponent.CodingKeys.iconName.stringValue,
                PaywallComponent.PartialIconComponent.CodingKeys.formats.stringValue,
                PaywallComponent.PartialIconComponent.CodingKeys.color.stringValue
            ])
        )
    }

    func testRawPropertiesPreserveUnknownKeysAndNestedValues() throws {
        let override = try Self.decodeIconOverride(
            properties: """
            {
                "future_property": {
                    "nested_values": ["first", 2, true, null],
                    "enabled": false
                }
            }
            """
        )

        XCTAssertEqual(
            override.rawProperties["futureProperty"],
            .object([
                "nestedValues": .array([
                    .string("first"),
                    .number(2),
                    .bool(true),
                    .null
                ]),
                "enabled": .bool(false)
            ])
        )
    }

    func testPresentedOverrideCarriesRawProperties() throws {
        let override = try Self.decodeIconOverride(
            properties: """
            {
                "icon_name": "star",
                "future_property": ["value"]
            }
            """
        )

        let presentedOverrides = [override].toPresentedOverrides()

        XCTAssertEqual(presentedOverrides.count, 1)
        let iconNameKey = PaywallComponent.PartialIconComponent.CodingKeys.iconName.stringValue
        XCTAssertEqual(
            presentedOverrides.first?.rawProperties[iconNameKey],
            .string("star")
        )
        XCTAssertEqual(
            presentedOverrides.first?.rawProperties["futureProperty"],
            .array([.string("value")])
        )
    }

    private static func decodeIconOverride(properties: String) throws -> IconOverride {
        let json = """
        {
            "conditions": [{ "type": "compact" }],
            "properties": \(properties)
        }
        """

        return try JSONDecoder.default.decode(IconOverride.self, from: Data(json.utf8))
    }

}

#endif
