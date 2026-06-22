//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsV2ViewTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class IntroEligibilityPackagesTests: TestCase {

    private let annual = TestData.annualPackage
    private let monthly = TestData.monthlyPackage
    private let weekly = TestData.weeklyPackage

    func testReturnsScreenPackagesWhenNoWorkflowPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual, monthly],
            workflowPackages: nil
        )

        expect(result) == [annual, monthly]
    }

    func testReturnsScreenPackagesWhenWorkflowPackagesEmpty() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual, monthly],
            workflowPackages: []
        )

        expect(result) == [annual, monthly]
    }

    // The bug: a workflow step with no package components (empty `paywallPackages`) inherits a selected
    // package from another step via `workflowPackages`. Eligibility must be computed for it, otherwise
    // `intro_offer_condition` overrides on that step never resolve.
    func testUsesWorkflowPackagesWhenScreenHasNoPackageComponents() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [],
            workflowPackages: [annual, monthly]
        )

        expect(result) == [annual, monthly]
    }

    func testMergesAndDeduplicatesScreenAndWorkflowPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual],
            workflowPackages: [annual, monthly, weekly]
        )

        // Screen packages come first, the inherited extras are appended once each.
        expect(result) == [annual, monthly, weekly]
    }

    func testDeduplicatesDuplicatesWithinWorkflowPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual],
            workflowPackages: [monthly, monthly]
        )

        expect(result) == [annual, monthly]
    }

    func testDeduplicatesDuplicatesWithinPaywallPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual, annual],
            workflowPackages: nil
        )

        expect(result) == [annual]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PromoEligibilityPackageInfosTests: TestCase {

    private let annual = TestData.annualPackage
    private let monthly = TestData.monthlyPackage

    private func pairs(
        _ infos: [(package: Package, promotionalOfferProductCode: String?)]
    ) -> [(String, String?)] {
        infos.map { ($0.package.identifier, $0.promotionalOfferProductCode) }
    }

    func testReturnsScreenInfosWhenNoWorkflowPackages() {
        let result = PaywallsV2View.promoEligibilityPackageInfos(
            paywallPackageInfos: [(annual, "promo_a")],
            workflowPackages: nil,
            workflowPromoOfferProductCodes: nil
        )

        expect(self.pairs(result)).to(equal([("$rc_annual", "promo_a")]))
    }

    // Mirrors the intro case: a packageless workflow step (empty `paywallPackageInfos`) inherits packages,
    // and the inherited promo offer code must be carried so `promo_offer_condition` can resolve.
    func testUsesInheritedPromoCodesWhenScreenHasNoPackageComponents() {
        let result = PaywallsV2View.promoEligibilityPackageInfos(
            paywallPackageInfos: [],
            workflowPackages: [annual, monthly],
            workflowPromoOfferProductCodes: ["$rc_annual": "promo_a"]
        )

        expect(self.pairs(result)).to(equal([("$rc_annual", "promo_a"), ("$rc_monthly", nil)]))
    }

    func testKeepsOnScreenInfoAndAppendsInheritedExtras() {
        let result = PaywallsV2View.promoEligibilityPackageInfos(
            paywallPackageInfos: [(annual, "screen_a")],
            workflowPackages: [annual, monthly],
            workflowPromoOfferProductCodes: ["$rc_annual": "wf_a", "$rc_monthly": "wf_m"]
        )

        // On-screen info wins for $rc_annual; only the missing $rc_monthly is appended.
        expect(self.pairs(result)).to(equal([("$rc_annual", "screen_a"), ("$rc_monthly", "wf_m")]))
    }

    func testDeduplicatesDuplicatesWithinPaywallPackageInfos() {
        let result = PaywallsV2View.promoEligibilityPackageInfos(
            paywallPackageInfos: [(annual, "promo_a"), (annual, "promo_a2")],
            workflowPackages: nil,
            workflowPromoOfferProductCodes: nil
        )

        // First occurrence wins; the duplicate is dropped.
        expect(self.pairs(result)).to(equal([("$rc_annual", "promo_a")]))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ShouldTrackPaywallEventsTests: TestCase {

    func testStandalonePaywallAlwaysReports() {
        // Standalone paywalls have no workflow screen_type and must keep reporting impressions.
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: nil,
            workflowScreenType: nil,
            isSingleStepFallback: false
        )) == true
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: nil,
            workflowScreenType: ["survey"],
            isSingleStepFallback: false
        )) == true
    }

    func testWorkflowPaywallStepReports() {
        // A step tagged as a paywall reports regardless of whether it is the fallback step.
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: true,
            workflowScreenType: [WorkflowScreenType.paywall],
            isSingleStepFallback: false
        )) == true
    }

    func testWorkflowUntaggedStepFallsBackToSingleStepFallback() {
        // Untagged workflows (nil screen_type, e.g. a backend that has not rolled out screen analytics)
        // fall back to the structural rule: only the singleStepFallbackId step reports.
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: true,
            workflowScreenType: nil,
            isSingleStepFallback: true
        )) == true
        // Untagged and not the fallback step → suppressed. This also covers the owner-confirmed case of a
        // workflow with no `singleStepFallbackId` at all: `WorkflowPaywallView` derives `isSingleStepFallback`
        // as `stepId == singleStepFallbackId`, which is `false` for every step when the optional fallback id
        // is absent, so no paywall events fire on any step (only workflow events).
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: true,
            workflowScreenType: nil,
            isSingleStepFallback: false
        )) == false
    }

    func testWorkflowStepTaggedNonPaywallDoesNotReport() {
        // A tagged step without `paywall` is suppressed even when it is the fallback step.
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: true,
            workflowScreenType: [],
            isSingleStepFallback: true
        )) == false
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: true,
            workflowScreenType: ["survey"],
            isSingleStepFallback: false
        )) == false
    }

    func testInactiveWorkflowPageGatedBySameRule() {
        // `isActiveWorkflowPage == false` is still a workflow page; the screen_type rule applies.
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: false,
            workflowScreenType: [WorkflowScreenType.paywall],
            isSingleStepFallback: false
        )) == true
        expect(PaywallsV2View.shouldTrackPaywallEvents(
            isActiveWorkflowPage: false,
            workflowScreenType: ["survey"],
            isSingleStepFallback: false
        )) == false
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WorkflowComponentInteractionLoggerTests: TestCase {

    private static let interactionData = PaywallEvent.ComponentInteractionData(
        componentType: .text,
        componentName: "link_copy",
        componentValue: "navigate_to_url"
    )

    func testNonPaywallStepGetsNoOpLogger() {
        var factoryInvoked = false
        let logger = PaywallsV2View.componentInteractionLogger(tracksPaywallEvents: false) {
            factoryInvoked = true
            return ComponentInteractionLogger { _ in true }
        }

        // A non-paywall step must emit no component_interaction: the real logger is never built and the
        // installed no-op reports nothing.
        expect(factoryInvoked) == false
        expect(logger(Self.interactionData)) == false
    }

    func testPaywallStepGetsRealLogger() async throws {
        let tracker = PaywallEventTracker(
            purchases: MockPurchases(
                purchase: { _, _, _ in
                    (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
                },
                restorePurchases: { TestData.customerInfo },
                trackEvent: { _ in },
                customerInfo: { TestData.customerInfo }
            ),
            eventDispatcher: PaywallEventTrackerTestDispatcher.value
        )
        let eventData: PaywallEvent.Data = .init(
            offering: TestData.offeringWithIntroOffer,
            paywall: TestData.paywallWithIntroOffer,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .init(identifier: "en_US"),
            darkMode: false,
            source: nil
        )
        tracker.trackPaywallImpression(eventData)

        let logger = PaywallsV2View.componentInteractionLogger(tracksPaywallEvents: true) {
            tracker.componentInteractionLogger(sessionID: eventData.sessionIdentifier)
        }

        // A paywall step uses the real session-bound logger, which reports the interaction.
        expect(logger(Self.interactionData)) == true

        await Task(priority: .low) {
            await Task.yield()
        }.value
    }

}

#endif
