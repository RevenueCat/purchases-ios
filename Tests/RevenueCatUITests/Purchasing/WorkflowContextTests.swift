//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowContextTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowContextTests: TestCase {

    // MARK: - WorkflowContext

    func testWorkflowContextStoresPresentedOfferingContext() throws {
        let offering = TestData.offeringWithIntroOffer
        let poc = PresentedOfferingContext(offeringIdentifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: poc
        )

        expect(context.presentedOfferingContext?.offeringIdentifier) == "offering_a"
    }

    func testWorkflowContextAllowsNilPresentedOfferingContext() throws {
        let offering = TestData.offeringWithIntroOffer
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.presentedOfferingContext).to(beNil())
    }

    // MARK: - resolveWorkflowContext

    func testResolveWorkflowContextThrowsWhenFlagIsOff() async throws {
        // In the unit test environment -EnableWorkflowsEndpoint is not a launch argument,
        // so workflowsEndpointEnabled returns false and resolveWorkflowContext must throw.
        let handler: PurchaseHandler = .mock()

        await expect {
            try await handler.resolveWorkflowContext(
                identifier: "offering_a",
                presentedOfferingContext: nil
            )
        }.to(throwError(PaywallError.offeringNotFound(identifier: "offering_a")))
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowContextTests {

    static func makeOfferings(_ offering: Offering) -> Offerings {
        return Offerings(
            offerings: [offering.identifier: offering],
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
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

    static func makeWorkflow() throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen" }
          },
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

}

#endif
