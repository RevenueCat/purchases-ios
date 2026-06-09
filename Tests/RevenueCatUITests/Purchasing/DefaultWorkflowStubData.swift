//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultWorkflowStubData.swift
//

import Foundation
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI

#if !os(tvOS)

/// Builds the workflow + offerings a test mock must return so a `PaywallView(offering:)` renders in
/// the always-on-workflows world. Mirrors the deployed backend, which wraps every offering in a
/// single-step workflow whose screen points back at that offering.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum DefaultWorkflowStubData {

    /// A single-step workflow whose initial screen wraps `offering`.
    static func workflow(wrapping offering: Offering) -> WorkflowDataResult {
        // swiftlint:disable:next force_try
        return try! Self.decodeWorkflow(offeringIdentifier: offering.identifier)
    }

    /// An `Offerings` bundle containing `offering`, so the workflow screen's offering resolves.
    static func offerings(containing offering: Offering) -> Offerings {
        return Offerings(
            offerings: [offering.identifier: offering],
            currentOfferingID: offering.identifier,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: offering.identifier,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )
    }

    private static func decodeWorkflow(offeringIdentifier: String) throws -> WorkflowDataResult {
        let json = """
        {
          "id": "wf_default",
          "display_name": "Default",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": {
              "id": "step_1",
              "type": "screen",
              "screen_id": "screen_1"
            }
          },
          "screens": {
            "screen_1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack",
                    "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color",
                    "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              },
              "offering_identifier": "\(offeringIdentifier)"
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = Data(json.utf8)
        let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
        return .init(workflow: workflow, enrolledVariants: nil)
    }

}

#endif
