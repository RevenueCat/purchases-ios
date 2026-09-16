//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPreviewRendererTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if DEBUG && !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
final class PaywallPreviewRendererTests: TestCase {

    func testLoadDecodesSampleJSONIntoOffering() throws {
        let fixture = try PaywallPreviewRenderer.load(json: PaywallPreviewRenderer.sampleJSON)

        expect(fixture.offering.identifier) == "json-preview"
        expect(fixture.offering.serverDescription) == "JSON paywall preview"
        expect(fixture.offering.availablePackages).to(haveCount(3))
        expect(fixture.offering.availablePackages.map(\.identifier)) == [
            "$rc_weekly",
            "$rc_monthly",
            "$rc_annual"
        ]
        expect(fixture.paywallComponents.data.templateName) == "components"
        expect(fixture.paywallComponents.data.defaultLocale) == "en_US"
        expect(
            fixture.paywallComponents.data.componentsLocalizations["en_US"]?["title"]
        ) == .string("JSON paywall preview")
    }

    func testLoadUsesCustomOfferingIdentifierAndPackages() throws {
        let fixture = try PaywallPreviewRenderer.load(
            json: PaywallPreviewRenderer.sampleJSON,
            offeringIdentifier: "custom-offering",
            serverDescription: "Custom",
            packages: []
        )

        expect(fixture.offering.identifier) == "custom-offering"
        expect(fixture.offering.serverDescription) == "Custom"
        expect(fixture.offering.availablePackages).to(beEmpty())
    }

    func testLoadThrowsOnInvalidJSON() {
        expect {
            try PaywallPreviewRenderer.load(json: "{ not-json")
        }.to(throwError())
    }

    func testLoadIgnoresUnknownDashboardKeys() throws {
        let json = """
        {
          "template_name": "components",
          "asset_base_url": "https://assets.pawwalls.com",
          "generated_by": "unit-test",
          "components_config": {
            "base": {
              "background": {
                "type": "color",
                "value": { "light": { "type": "hex", "value": "#ffffffff" } }
              },
              "stack": {
                "type": "stack",
                "components": [],
                "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
                "dimension": {
                  "type": "vertical",
                  "alignment": "center",
                  "distribution": "center"
                }
              }
            }
          },
          "components_localizations": { "en_US": {} },
          "default_locale": "en_US"
        }
        """

        let fixture = try PaywallPreviewRenderer.load(json: json, packages: [])
        expect(fixture.paywallComponents.data.templateName) == "components"
    }

}

#endif
