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

#if !os(tvOS)
    func testCachedInitialOfferingReturnsNilForAllContent() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [cachedOffering],
            currentOfferingID: cachedOffering.identifier
        )

        expect(handler.cachedInitialOffering(
            for: .offering(cachedOffering)
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .defaultOffering
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil)
        )).to(beNil())
    }

    func testResolvePaywallViewDataReturnsWorkflowContextForWorkflowOfferingContent() async throws {
        // `paywall: nil` marks a non-legacy offering, so the workflow path is taken.
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
            .withPresentedOfferingContext(Self.createPresentedOfferingContext(offeringIdentifier: "offering_a"))
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([initialOffering, workflowOffering])
        }
        purchases.workflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let result = try await handler.resolvePaywallViewData(
            for: .offering(initialOffering)
        )

        expect(result.offering.identifier) == workflowOffering.identifier
        expect(result.offering.paywallComponents).toNot(beNil())
        expect(result.workflowContext?.initialOffering.identifier) == workflowOffering.identifier
        expect(result.workflowContext?.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier

        let packageContext = try XCTUnwrap(result.offering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
        expect(packageContext.placementIdentifier) == "placement_offering_a"
        expect(packageContext.targetingContext?.revision) == 7
        expect(packageContext.targetingContext?.ruleId) == "targeting_rule_offering_a"
    }

    func testResolvePaywallViewDataReturnsWorkflowContextForWorkflowDefaultOffering() async throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
            .withPresentedOfferingContext(.init(offeringIdentifier: "offering_a"))
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings(
                [initialOffering, workflowOffering],
                currentOfferingID: initialOffering.identifier,
                targeting: .init(revision: 7, ruleId: "targeting_rule_offering_a")
            )
        }
        purchases.workflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let result = try await handler.resolvePaywallViewData(
            for: .defaultOffering
        )

        expect(result.offering.identifier) == workflowOffering.identifier
        expect(result.offering.paywallComponents).toNot(beNil())
        expect(result.workflowContext?.initialOffering.identifier) == workflowOffering.identifier
        expect(result.workflowContext?.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier

        let packageContext = try XCTUnwrap(result.offering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
        expect(packageContext.targetingContext?.revision) == 7
        expect(packageContext.targetingContext?.ruleId) == "targeting_rule_offering_a"
    }

    func testResolvePaywallViewDataReturnsWorkflowContextForWorkflowOfferingIdentifier() async throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
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
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: presentedOfferingContext)
        )

        expect(result.offering.identifier) == workflowOffering.identifier
        expect(result.offering.paywallComponents).toNot(beNil())
        expect(result.workflowContext?.initialOffering.identifier) == workflowOffering.identifier
        expect(result.workflowContext?.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier
        expect(result.workflowContext?.workflow.initialStepId) == "step_1"

        let packageContext = try XCTUnwrap(result.offering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
    }

    func testResolvePaywallViewDataThrowsWithScreenOfferingIdWhenScreenOfferingMissing() async throws {
        // The workflow screen resolves to "offering_b", but the offerings snapshot only contains the
        // trigger offering "offering_a". The error must report the screen's offering id that was
        // actually missing, not the trigger offering used to look up the workflow.
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([initialOffering], currentOfferingID: initialOffering.identifier)
        }
        purchases.workflowBlock = { _ in
            try Self.createWorkflowDataResult(offeringIdentifier: "offering_b")
        }

        do {
            _ = try await handler.resolvePaywallViewData(
                for: .offering(initialOffering)
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch let PaywallError.offeringNotFound(identifier) {
            expect(identifier) == "offering_b"
        }
    }

    func testCachedInitialWorkflowContextReturnsContextForWorkflowOfferingContentOnWarmCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
            .withPresentedOfferingContext(Self.createPresentedOfferingContext(offeringIdentifier: "offering_a"))
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings([initialOffering, workflowOffering])
        purchases.cachedWorkflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try? Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let context = try XCTUnwrap(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering)
        ))

        expect(context.initialOffering.identifier) == workflowOffering.identifier
        expect(context.initialOffering.paywallComponents).toNot(beNil())
        expect(context.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier

        let packageContext = try XCTUnwrap(context.initialOffering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
        expect(packageContext.placementIdentifier) == "placement_offering_a"
        expect(packageContext.targetingContext?.ruleId) == "targeting_rule_offering_a"
    }

    func testCachedInitialWorkflowContextReturnsContextForWorkflowDefaultOfferingOnWarmCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
            .withPresentedOfferingContext(.init(offeringIdentifier: "offering_a"))
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering, workflowOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try? Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let context = try XCTUnwrap(handler.cachedInitialWorkflowContext(
            for: .defaultOffering
        ))

        expect(context.initialOffering.identifier) == workflowOffering.identifier
        expect(context.initialOffering.paywallComponents).toNot(beNil())
    }

    func testCachedInitialWorkflowContextReturnsContextForWorkflowOfferingIdentifierOnWarmCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)
        let presentedOfferingContext = PresentedOfferingContext(offeringIdentifier: initialOffering.identifier)

        purchases.cachedOfferings = Self.createOfferings([initialOffering, workflowOffering])
        purchases.cachedWorkflowBlock = { offeringIdentifier in
            expect(offeringIdentifier) == initialOffering.identifier
            return try? Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        let context = try XCTUnwrap(handler.cachedInitialWorkflowContext(
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: presentedOfferingContext)
        ))

        expect(context.initialOffering.identifier) == workflowOffering.identifier
        expect(context.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier
        expect(context.workflow.initialStepId) == "step_1"
    }

    func testCachedInitialWorkflowContextReturnsNilWhenWorkflowNotCached() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { _ in nil }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering)
        )).to(beNil())
    }

    func testCachedInitialWorkflowContextReturnsNilWhenBaseOfferingMissingFromCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a", paywall: nil)
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        // The workflow is cached, but its screen's offering ("offering_b") is absent from the cached
        // offerings: a partial hit must return nil (loading) rather than force-unwrap.
        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { _ in
            try? Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering)
        )).to(beNil())
    }

    func testCachedInitialWorkflowContextReturnsNilWhenNoCachedOfferings() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = nil
        purchases.cachedWorkflowBlock = { _ in
            try? Self.createWorkflowDataResult(offeringIdentifier: workflowOffering.identifier)
        }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering)
        )).to(beNil())
    }

    func testCachedInitialWorkflowContextReturnsNilWhenOfferingHasLegacyPaywall() throws {
        // Even with a cached workflow, an offering with a legacy paywall must not seed a workflow:
        // it renders legacy via the async path, matching the gate in resolvePaywallViewData.
        let initialOffering = Self.createOffering(identifier: "offering_a")
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering, workflowOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { _ in
            XCTFail("Workflow cache should not be read for an offering with a legacy paywall")
            return nil
        }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering)
        )).to(beNil())
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

    static func createOfferings(
        _ offerings: [Offering],
        currentOfferingID: String? = nil,
        targeting: Offerings.Targeting? = nil
    ) -> Offerings {
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: currentOfferingID,
            placements: nil,
            targeting: targeting,
            contents: .init(
                response: .init(
                    currentOfferingId: currentOfferingID,
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

    /// `paywall` defaults to a legacy paywall. Pass `paywall: nil` for a workflow-eligible offering
    /// (the workflow gate routes `offering.paywall == nil` offerings through the workflows endpoint).
    static func createOffering(identifier: String, paywall: PaywallData? = TestData.paywallWithIntroOffer) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: paywall,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

#if !os(tvOS)
    static func createPresentedOfferingContext(offeringIdentifier: String) -> PresentedOfferingContext {
        return .init(
            offeringIdentifier: offeringIdentifier,
            placementIdentifier: "placement_\(offeringIdentifier)",
            targetingContext: .init(
                revision: 7,
                ruleId: "targeting_rule_\(offeringIdentifier)"
            )
        )
    }

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
