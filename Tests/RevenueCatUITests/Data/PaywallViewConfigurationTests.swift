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
    func testCachedInitialOfferingReturnsNilForAllContentWhenRemoteConfigEnabled() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [cachedOffering],
            currentOfferingID: cachedOffering.identifier
        )

        expect(handler.cachedInitialOffering(
            for: .offering(cachedOffering),
            remoteConfigEnabled: true
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .defaultOffering,
            remoteConfigEnabled: true
        )).to(beNil())
        expect(handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil),
            remoteConfigEnabled: true
        )).to(beNil())
    }

    func testCachedInitialOfferingUsesCachedOfferingsWhenRemoteConfigDisabled() {
        let cachedOffering = TestData.offeringWithNoIntroOffer
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.cachedOfferings = Self.createOfferings(
            [cachedOffering],
            currentOfferingID: cachedOffering.identifier
        )

        expect(handler.cachedInitialOffering(
            for: .offering(cachedOffering),
            remoteConfigEnabled: false
        )) === cachedOffering
        expect(handler.cachedInitialOffering(
            for: .defaultOffering,
            remoteConfigEnabled: false
        )?.identifier) == cachedOffering.identifier
        expect(handler.cachedInitialOffering(
            for: .offeringIdentifier(cachedOffering.identifier, presentedOfferingContext: nil),
            remoteConfigEnabled: false
        )?.identifier) == cachedOffering.identifier
    }

    func testResolvePaywallViewDataReturnsNilWorkflowContextWhenRemoteConfigDisabled() async throws {
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
            XCTFail("Workflow endpoint should not be fetched when remoteConfigEnabled is false")
            throw ErrorCode.configurationError
        }

        let offeringResult = try await handler.resolvePaywallViewData(
            for: .offering(initialOffering),
            remoteConfigEnabled: false
        )
        let defaultOfferingResult = try await handler.resolvePaywallViewData(
            for: .defaultOffering,
            remoteConfigEnabled: false
        )
        let offeringIdentifierResult = try await handler.resolvePaywallViewData(
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: nil),
            remoteConfigEnabled: false
        )

        expect(offeringResult.offering.identifier) == initialOffering.identifier
        expect(offeringResult.workflowContext).to(beNil())
        expect(defaultOfferingResult.offering.identifier) == initialOffering.identifier
        expect(defaultOfferingResult.workflowContext).to(beNil())
        expect(offeringIdentifierResult.offering.identifier) == initialOffering.identifier
        expect(offeringIdentifierResult.workflowContext).to(beNil())
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
            for: .offering(initialOffering),
            remoteConfigEnabled: true
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
            for: .defaultOffering,
            remoteConfigEnabled: true
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
            for: .offeringIdentifier(initialOffering.identifier, presentedOfferingContext: presentedOfferingContext),
            remoteConfigEnabled: true
        )

        expect(result.offering.identifier) == workflowOffering.identifier
        expect(result.offering.paywallComponents).toNot(beNil())
        expect(result.workflowContext?.initialOffering.identifier) == workflowOffering.identifier
        expect(result.workflowContext?.presentedOfferingContext?.offeringIdentifier) == initialOffering.identifier
        expect(result.workflowContext?.workflow.initialStepId) == "step_1"

        let packageContext = try XCTUnwrap(result.offering.availablePackages.first?.presentedOfferingContext)
        expect(packageContext.offeringIdentifier) == initialOffering.identifier
    }

    func testResolvePaywallViewDataFallsBackToOfferingsPaywallWhenWorkflowFetchFails() async throws {
        let (offering, paywallComponents, purchases, handler) = try Self.createOfferingWithFallbackFixture()
        var workflowFetchAttempted = false
        purchases.workflowBlock = { _ in
            workflowFetchAttempted = true
            throw ErrorCode.networkError
        }

        let result = try await handler.resolvePaywallViewData(
            for: .offering(offering),
            remoteConfigEnabled: true
        )

        expect(workflowFetchAttempted) == true
        expect(result.offering.identifier) == offering.identifier
        expect(result.offering.paywallComponents?.data) == paywallComponents.data
        expect(result.workflowContext).to(beNil())
    }

    func testResolvePaywallViewDataThrowsWhenWorkflowScreenOfferingMissingEvenWithFallbackAvailable() async throws {
        // A structural workflow misconfiguration (unlike a fetch failure) must still surface, even
        // with a fallback available: mirrors isWorkflowFetchFallbackEligible's PaywallError exclusion.
        let (offering, _, purchases, handler) = try Self.createOfferingWithFallbackFixture()
        purchases.workflowBlock = { _ in
            try Self.createWorkflowDataResult(offeringIdentifier: "offering_b")
        }

        do {
            _ = try await handler.resolvePaywallViewData(
                for: .offering(offering),
                remoteConfigEnabled: true
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch let PaywallError.offeringNotFound(identifier) {
            expect(identifier) == "offering_b"
        }
    }

    func testResolvePaywallViewDataThrowsOnCancellationEvenWithFallbackAvailable() async throws {
        // Cancellation must propagate even with a fallback available: mirrors
        // isWorkflowFetchFallbackEligible's CancellationError exclusion.
        let (offering, _, purchases, handler) = try Self.createOfferingWithFallbackFixture()
        purchases.workflowBlock = { _ in
            throw CancellationError()
        }

        do {
            _ = try await handler.resolvePaywallViewData(
                for: .offering(offering),
                remoteConfigEnabled: true
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch is CancellationError {
            // Expected.
        }
    }

    func testResolvePaywallViewDataThrowsWhenWorkflowFetchFailsWithNoFallback() async throws {
        // An offering with neither a legacy paywall nor paywall components has nothing to fall back
        // to, so a workflow fetch failure must still surface as an error.
        let offering = Self.createOffering(identifier: "offering_a", paywall: nil)
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([offering], currentOfferingID: offering.identifier)
        }
        purchases.workflowBlock = { _ in
            throw ErrorCode.networkError
        }

        do {
            _ = try await handler.resolvePaywallViewData(
                for: .offering(offering),
                remoteConfigEnabled: true
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch {
            expect((error as? ErrorCode)) == ErrorCode.networkError
        }
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
                for: .offering(initialOffering),
                remoteConfigEnabled: true
            )
            XCTFail("Expected resolvePaywallViewData to throw")
        } catch let PaywallError.offeringNotFound(identifier) {
            expect(identifier) == "offering_b"
        }
    }

    func testResolvePaywallViewDataRendersLegacyWhenOfferingHasLegacyPaywall() async throws {
        // A legacy paywall (`offering.paywall != nil`) renders directly, with no workflow fetch.
        let offering = Self.createOffering(identifier: "offering_a")
            .withPresentedOfferingContext(Self.createPresentedOfferingContext(offeringIdentifier: "offering_a"))
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([offering], currentOfferingID: offering.identifier)
        }
        purchases.workflowBlock = { _ in
            XCTFail("Workflow should not be fetched when the offering has a legacy paywall")
            throw ErrorCode.configurationError
        }

        let result = try await handler.resolvePaywallViewData(
            for: .offering(offering),
            remoteConfigEnabled: true
        )

        expect(result.offering.identifier) == offering.identifier
        expect(result.workflowContext).to(beNil())
    }

    func testResolvePaywallViewDataRendersLegacyForDefaultOfferingWithLegacyPaywall() async throws {
        let offering = Self.createOffering(identifier: "offering_a")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([offering], currentOfferingID: offering.identifier)
        }
        purchases.workflowBlock = { _ in
            XCTFail("Workflow should not be fetched when the offering has a legacy paywall")
            throw ErrorCode.configurationError
        }

        let result = try await handler.resolvePaywallViewData(
            for: .defaultOffering,
            remoteConfigEnabled: true
        )

        expect(result.offering.identifier) == offering.identifier
        expect(result.workflowContext).to(beNil())
    }

    func testResolvePaywallViewDataRendersLegacyForOfferingIdentifierWithLegacyPaywall() async throws {
        let offering = Self.createOffering(identifier: "offering_a")
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)
        let presentedOfferingContext = PresentedOfferingContext(offeringIdentifier: offering.identifier)

        purchases.offeringsBlock = {
            Self.createOfferings([offering], currentOfferingID: offering.identifier)
        }
        purchases.workflowBlock = { _ in
            XCTFail("Workflow should not be fetched when the offering has a legacy paywall")
            throw ErrorCode.configurationError
        }

        let result = try await handler.resolvePaywallViewData(
            for: .offeringIdentifier(offering.identifier, presentedOfferingContext: presentedOfferingContext),
            remoteConfigEnabled: true
        )

        expect(result.offering.identifier) == offering.identifier
        expect(result.offering.presentedOfferingContext?.offeringIdentifier) == offering.identifier
        expect(result.workflowContext).to(beNil())
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
            uiConfig: PreviewUIConfig.make(),
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

    /// A dashboard-authored V2 paywall independent of any workflow, built from the same screen shape
    /// a workflow would map, to simulate an offering with a fallback paywall already delivered.
    static func createPaywallComponents(offeringIdentifier: String) throws -> Offering.PaywallComponents {
        let workflow = try Self.createWorkflow(offeringIdentifier: offeringIdentifier)
        let screen = try XCTUnwrap(workflow.screens["screen_1"])
        return WorkflowScreenMapper.toPaywallComponents(screen: screen, uiConfig: PreviewUIConfig.make())
    }

    /// A non-legacy offering with a fallback paywall already available, wired into a handler whose
    /// offerings fetch resolves it. Shared by the fallback-eligibility tests, which each only need to
    /// set `workflowBlock` and assert.
    static func createOfferingWithFallbackFixture(
        identifier: String = "offering_a"
    ) throws -> (
        offering: Offering,
        paywallComponents: Offering.PaywallComponents,
        purchases: MockPurchases,
        handler: PurchaseHandler
    ) {
        let paywallComponents = try Self.createPaywallComponents(offeringIdentifier: identifier)
        let offering = Self.createOffering(identifier: identifier, paywall: nil)
            .withPaywallComponents(paywallComponents)
        let purchases = Self.createMockPurchases()
        let handler = Self.createPurchaseHandler(purchases: purchases)

        purchases.offeringsBlock = {
            Self.createOfferings([offering], currentOfferingID: offering.identifier)
        }

        return (offering, paywallComponents, purchases, handler)
    }
#endif

}
