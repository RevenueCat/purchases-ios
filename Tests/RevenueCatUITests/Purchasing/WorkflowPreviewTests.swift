//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPreviewTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowPreviewTests: TestCase {

    func testMakeContextBuildsWorkflowContextFromInjectedData() throws {
        let baseOffering = Self.makeOffering(identifier: "offering_a")
        let workflow = try Self.makeWorkflow(screenOfferingIdentifier: "offering_a")

        let context = try WorkflowPreview.makeContext(workflow: workflow, offerings: [baseOffering])

        // The rendered offering is the screen's offering with the workflow screen's components applied.
        expect(context.initialOffering.identifier) == "offering_a"
        expect(context.initialOffering.paywallComponents).toNot(beNil())
        expect(context.workflow.id) == "wf_test"
    }

    func testMakeContextPropagatesPresentedOfferingContext() throws {
        let baseOffering = Self.makeOffering(identifier: "offering_a")
        let workflow = try Self.makeWorkflow(screenOfferingIdentifier: "offering_a")
        let presentedOfferingContext = PresentedOfferingContext(offeringIdentifier: "offering_a")

        let context = try WorkflowPreview.makeContext(
            workflow: workflow,
            offerings: [baseOffering],
            presentedOfferingContext: presentedOfferingContext
        )

        expect(context.presentedOfferingContext?.offeringIdentifier) == "offering_a"
    }

    func testMakeContextThrowsWhenScreenOfferingMissingFromOfferings() throws {
        // The workflow screen resolves to "offering_b", but only "offering_a" is supplied.
        let workflow = try Self.makeWorkflow(screenOfferingIdentifier: "offering_b")

        do {
            _ = try WorkflowPreview.makeContext(
                workflow: workflow,
                offerings: [Self.makeOffering(identifier: "offering_a")]
            )
            XCTFail("Expected makeContext to throw")
        } catch let PaywallError.offeringNotFound(identifier) {
            expect(identifier) == "offering_b"
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowPreviewTests {

    /// A packages-only offering (no paywall components), as the preview seam expects.
    static func makeOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: nil,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

    /// Builds a single-screen workflow using the `@_spi(Internal)` initializers (C-1), sourcing the
    /// `componentsConfig`/`uiConfig` sub-objects from JSON since hand-building them is impractical.
    static func makeWorkflow(screenOfferingIdentifier: String) throws -> PublishedWorkflow {
        let screen = WorkflowScreen(
            name: nil,
            templateName: "tmpl",
            assetBaseURL: try XCTUnwrap(URL(string: "https://assets.revenuecat.com")),
            componentsConfig: try Self.makeComponentsConfig(),
            componentsLocalizations: [:],
            defaultLocale: "en_US",
            offeringIdentifier: screenOfferingIdentifier
        )
        let step = WorkflowStep(id: "step_1", type: "screen", screenId: "screen_1")

        return PublishedWorkflow(
            id: "wf_test",
            displayName: "Test",
            initialStepId: "step_1",
            singleStepFallbackId: nil,
            steps: ["step_1": step],
            screens: ["screen_1": screen],
            uiConfig: try Self.makeUIConfig()
        )
    }

    static func makeComponentsConfig() throws -> PaywallComponentsData.ComponentsConfig {
        let json = """
        {
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
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PaywallComponentsData.ComponentsConfig.self, from: data)
    }

    static func makeUIConfig() throws -> UIConfig {
        let json = """
        {
          "app": { "colors": {}, "fonts": {} },
          "localizations": {}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(UIConfig.self, from: data)
    }

}

#endif
