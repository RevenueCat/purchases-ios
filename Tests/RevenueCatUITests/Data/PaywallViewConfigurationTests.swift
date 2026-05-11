//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewConfigurationTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallViewConfigurationTests: TestCase {

    func testCachedInitialOfferingReturnsProvidedOfferingForOfferingContent() {
        let handler = Self.createPurchaseHandler()
        let offering = TestData.offeringWithNoIntroOffer

        let result = handler.cachedInitialOffering(for: .offering(offering))

        expect(result) === offering
    }

    func testResolveOfferingOrThrowReturnsProvidedOfferingForOfferingContent() async throws {
        let handler = Self.createPurchaseHandler()
        let offering = TestData.offeringWithNoIntroOffer

        let result = try await handler.resolveOfferingOrThrow(for: .offering(offering))

        expect(result) === offering
    }

    func testOfferingIdentifierCachedInitialOfferingDependsOnWorkflowResolutionMode() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(cachedOffering)

        let result = handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil)
        )

        expect(result?.identifier) == cachedOffering.identifier
    }

#if !os(tvOS)
    func testResolvePaywallViewDataReturnsWorkflowContextForWorkflowOfferingIdentifier() async throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)
        let presentedOfferingContext = PresentedOfferingContext(offeringIdentifier: initialOffering.identifier)

        purchases.offeringsBlock = {
            Self.createOfferings([initialOffering, workflowOffering])
        }
        purchases.workflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let result = try await handler.resolvePaywallViewData(
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: presentedOfferingContext),
            workflowsEndpointEnabled: true
        )

        expect(result.offering.identifier) == workflowOffering.identifier
        expect(result.offering.paywallComponents).toNot(beNil())
        expect(result.workflowContext?.initialOffering.identifier) == workflowOffering.identifier
        expect(result.workflowContext?.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier
        expect(result.workflowContext?.workflow.initialStepId) == "step_1"

        let packageContext = try XCTUnwrap(result.offering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
    }
#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewConfigurationTests {

    static func createPurchaseHandler(purchases: MockPurchases = createMockPurchases()) -> PurchaseHandler {
        return PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases)
        )
    }

    static func createMockPurchases() -> MockPurchases {
        return MockPurchases { _, _, _ in
            (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        } restorePurchases: {
            TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            TestData.customerInfo
        }
    }

    static func createOfferings(_ offering: Offering) -> Offerings {
        return self.createOfferings([offering])
    }

    static func createOfferings(_ offerings: [Offering]) -> Offerings {
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
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

    static func createOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: TestData.paywallWithIntroOffer,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

#if !os(tvOS)
    static func createWorkflowDataResult(offeringIdentifier: String) throws -> WorkflowDataResult {
        return .init(
            workflow: try self.createWorkflow(offeringIdentifier: offeringIdentifier),
            enrolledVariants: nil
        )
    }

    static func createWorkflow(offeringIdentifier: String) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
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
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }
#endif

}
