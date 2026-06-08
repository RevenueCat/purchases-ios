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
    func testCachedInitialOfferingReturnsNilForAllContentWhenWorkflowsEndpointEnabled() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [cachedOffering],
            currentOfferingID: cachedOffering.identifier
        )

        expect(handler.cachedInitialOffering(
            for: .offering(cachedOffering),
            workflowsEndpointEnabled: true
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .defaultOffering,
            workflowsEndpointEnabled: true
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil),
            workflowsEndpointEnabled: true
        )).to(beNil())
    }

    func testCachedInitialOfferingUsesCachedOfferingsWhenWorkflowsEndpointDisabled() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [cachedOffering],
            currentOfferingID: cachedOffering.identifier
        )

        expect(handler.cachedInitialOffering(
            for: .offering(cachedOffering),
            workflowsEndpointEnabled: false
        )) === cachedOffering
        expect(handler.cachedInitialOffering(
            for: .defaultOffering,
            workflowsEndpointEnabled: false
        )?.identifier) == cachedOffering.identifier
        expect(handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil),
            workflowsEndpointEnabled: false
        )?.identifier) == cachedOffering.identifier
    }

    func testResolvePaywallViewDataReturnsNilWorkflowContextWhenWorkflowsEndpointDisabled() async throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
            .withPresentedOfferingContext(Self.createPresentedOfferingContext(offeringIdentifier: "offering_a"))
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings(
                [initialOffering],
                currentOfferingID: initialOffering.identifier
            )
        }
        purchases.workflowBlock = { _ in
            XCTFail("Workflow endpoint should not be fetched when workflowsEndpointEnabled is false")
            throw ErrorCode.configurationError
        }

        let offeringResult = try await handler.resolvePaywallViewData(
            for: .offering(initialOffering),
            workflowsEndpointEnabled: false
        )
        let defaultOfferingResult = try await handler.resolvePaywallViewData(
            for: .defaultOffering,
            workflowsEndpointEnabled: false
        )
        let offeringIdentifierResult = try await handler.resolvePaywallViewData(
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: nil),
            workflowsEndpointEnabled: false
        )

        expect(offeringResult.offering.identifier) == initialOffering.identifier
        expect(offeringResult.workflowContext).to(beNil())
        expect(defaultOfferingResult.offering.identifier) == initialOffering.identifier
        expect(defaultOfferingResult.workflowContext).to(beNil())
        expect(offeringIdentifierResult.offering.identifier) == initialOffering.identifier
        expect(offeringIdentifierResult.workflowContext).to(beNil())
    }

    func testResolvePaywallViewDataReturnsWorkflowContextForWorkflowOfferingContent() async throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .offering(initialOffering),
            workflowsEndpointEnabled: true
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
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .defaultOffering,
            workflowsEndpointEnabled: true
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

    func testResolvePaywallViewDataThrowsWithScreenOfferingIdWhenScreenOfferingMissing() async throws {
        // The workflow screen resolves to "offering_b", but the offerings snapshot only contains the
        // trigger offering "offering_a". The error must report the screen's offering id that was
        // actually missing, not the trigger offering used to look up the workflow.
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
                for: .offering(initialOffering),
                workflowsEndpointEnabled: true
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch let PaywallError.offeringNotFound(identifier) {
            expect(identifier) == "offering_b"
        }
    }

    func testCachedInitialWorkflowContextReturnsNilWhenWorkflowsEndpointDisabled() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
        let workflowOffering = Self.createOffering(identifier: "offering_b")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering, workflowOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { _ in
            XCTFail("Workflow cache should not be read when workflowsEndpointEnabled is false")
            return nil
        }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering),
            workflowsEndpointEnabled: false
        )).to(beNil())
        expect(handler.cachedInitialWorkflowContext(
            for: .defaultOffering,
            workflowsEndpointEnabled: false
        )).to(beNil())
        expect(handler.cachedInitialWorkflowContext(
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: nil),
            workflowsEndpointEnabled: false
        )).to(beNil())
    }

    func testCachedInitialWorkflowContextReturnsContextForWorkflowOfferingContentOnWarmCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .offering(initialOffering),
            workflowsEndpointEnabled: true
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
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .defaultOffering,
            workflowsEndpointEnabled: true
        ))

        expect(context.initialOffering.identifier) == workflowOffering.identifier
        expect(context.initialOffering.paywallComponents).toNot(beNil())
    }

    func testCachedInitialWorkflowContextReturnsContextForWorkflowOfferingIdentifierOnWarmCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: presentedOfferingContext),
            workflowsEndpointEnabled: true
        ))

        expect(context.initialOffering.identifier) == workflowOffering.identifier
        expect(context.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier
        expect(context.workflow.initialStepId) == "step_1"
    }

    func testCachedInitialWorkflowContextReturnsNilWhenWorkflowNotCached() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [initialOffering],
            currentOfferingID: initialOffering.identifier
        )
        purchases.cachedWorkflowBlock = { _ in nil }

        expect(handler.cachedInitialWorkflowContext(
            for: .offering(initialOffering),
            workflowsEndpointEnabled: true
        )).to(beNil())
    }

    func testCachedInitialWorkflowContextReturnsNilWhenBaseOfferingMissingFromCache() throws {
        let initialOffering = Self.createOffering(identifier: "offering_a")
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
            for: .offering(initialOffering),
            workflowsEndpointEnabled: true
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
            for: .offering(initialOffering),
            workflowsEndpointEnabled: true
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
