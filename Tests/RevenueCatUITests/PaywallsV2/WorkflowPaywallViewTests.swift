//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPaywallViewTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowPaywallViewTests: TestCase {

    func testDismissalActionDismissesWorkflowAfterPurchaseEvenWhenBackNavigationIsAvailable() {
        let action = WorkflowPaywallView.dismissalAction(
            canNavigateBack: true,
            hasPurchasedInSession: true
        )

        expect(action) == .dismissWorkflow
    }

    func testDismissalActionNavigatesBackWhenPurchaseHasNotCompleted() {
        let action = WorkflowPaywallView.dismissalAction(
            canNavigateBack: true,
            hasPurchasedInSession: false
        )

        expect(action) == .navigateBack
    }

    func testDismissalActionDismissesWorkflowAtRootStep() {
        let action = WorkflowPaywallView.dismissalAction(
            canNavigateBack: false,
            hasPurchasedInSession: false
        )

        expect(action) == .dismissWorkflow
    }

    func testDismissalActionDismissesWorkflowAtRootStepAfterPurchase() {
        let action = WorkflowPaywallView.dismissalAction(
            canNavigateBack: false,
            hasPurchasedInSession: true
        )

        expect(action) == .dismissWorkflow
    }

    func testTransitionStateStartsWithoutOutgoingPage() {
        let state = WorkflowPageTransitionState(currentPage: "step_1")

        expect(state.currentPage) == "step_1"
        expect(state.outgoingPage).to(beNil())
        expect(state.isTransitioning) == false
        expect(state.progress) == 1
    }

    func testForwardTransitionKeepsOutgoingPageOnTopWhileItSlidesLeft() {
        var state = WorkflowPageTransitionState(currentPage: "step_1")

        state.beginTransition(to: "step_2", direction: .forward)

        expect(state.currentPage) == "step_2"
        expect(state.outgoingPage) == "step_1"
        expect(state.progress) == 0
        expect(state.offset(for: .current, width: 320)) == 320
        expect(state.offset(for: .outgoing, width: 320)) == 0
        expect(state.zIndex(for: .current)) == 0
        expect(state.zIndex(for: .outgoing)) == 1
        expect(state.headerButtonOpacity(for: .current)) == 0
        expect(state.headerButtonOpacity(for: .outgoing)) == 1

        state.advanceAnimation()

        expect(state.offset(for: .current, width: 320)) == 0
        expect(state.offset(for: .outgoing, width: 320)) == -320
        expect(state.headerButtonOpacity(for: .current)) == 1
        expect(state.headerButtonOpacity(for: .outgoing)) == 0
    }

    func testBackTransitionKeepsOutgoingPageOnTopWhileItSlidesRight() {
        var state = WorkflowPageTransitionState(currentPage: "step_2")

        state.beginTransition(to: "step_1", direction: .back)

        expect(state.currentPage) == "step_1"
        expect(state.outgoingPage) == "step_2"
        expect(state.offset(for: .current, width: 320)) == -320
        expect(state.offset(for: .outgoing, width: 320)) == 0
        expect(state.zIndex(for: .current)) == 0
        expect(state.zIndex(for: .outgoing)) == 1
        expect(state.headerButtonOpacity(for: .current)) == 0
        expect(state.headerButtonOpacity(for: .outgoing)) == 1

        state.advanceAnimation()

        expect(state.offset(for: .current, width: 320)) == 0
        expect(state.offset(for: .outgoing, width: 320)) == 320
        expect(state.headerButtonOpacity(for: .current)) == 1
        expect(state.headerButtonOpacity(for: .outgoing)) == 0
    }

    func testCompletingTransitionDropsOutgoingPage() {
        var state = WorkflowPageTransitionState(currentPage: "step_1")

        state.beginTransition(to: "step_2", direction: .forward)
        state.advanceAnimation()
        state.completeTransition()

        expect(state.currentPage) == "step_2"
        expect(state.outgoingPage).to(beNil())
        expect(state.isTransitioning) == false
        expect(state.progress) == 1
    }

    func testInvalidTargetSkipsAnimationAndClearsTheCurrentPage() {
        var state = WorkflowPageTransitionState(currentPage: "step_1")

        state.beginTransition(to: nil, direction: .forward)

        expect(state.currentPage).to(beNil())
        expect(state.outgoingPage).to(beNil())
        expect(state.isTransitioning) == false
        expect(state.progress) == 1
    }

}

// MARK: - computeFallbackPackage tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testComputeFallbackPackageReturnsNilWhenNoFallbackStepId() throws {
        let context = try Self.makeContext(singleStepFallbackId: nil)
        expect(WorkflowPaywallView.computeFallbackPackage(from: context)).to(beNil())
    }

    func testComputeFallbackPackageReturnsNilWhenFallbackIdPointsToMissingStep() throws {
        let context = try Self.makeContext(singleStepFallbackId: "nonexistent_step")
        expect(WorkflowPaywallView.computeFallbackPackage(from: context)).to(beNil())
    }

    func testComputeFallbackPackageReturnsIsSelectedByDefaultPackage() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            fallbackPackages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: true)
            ]
        )
        let result = WorkflowPaywallView.computeFallbackPackage(from: context)
        expect(result?.identifier) == "$rc_annual"
    }

    func testComputeFallbackPackageReturnsFirstPackageWhenNoneIsDefault() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            fallbackPackages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: false)
            ]
        )
        let result = WorkflowPaywallView.computeFallbackPackage(from: context)
        expect(result?.identifier) == "$rc_monthly"
    }

    func testComputeFallbackPackageReturnsNilForPackagelessFallbackStep() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            fallbackPackages: []
        )
        let result = WorkflowPaywallView.computeFallbackPackage(from: context)
        expect(result).to(beNil())
    }

}

// MARK: - Helpers for computeFallbackPackage tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowPaywallViewTests {

    typealias PackageSpec = (id: String, isDefault: Bool)

    static func makeContext(
        singleStepFallbackId: String?,
        fallbackPackages: [PackageSpec] = []
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let workflow = try makeWorkflow(
            singleStepFallbackId: singleStepFallbackId,
            fallbackPackages: fallbackPackages,
            offeringId: offeringId
        )
        let packages = fallbackPackages.map { spec in
            Package(
                identifier: spec.id,
                packageType: .custom,
                storeProduct: TestData.monthlyPackage.storeProduct,
                offeringIdentifier: offeringId,
                webCheckoutUrl: nil
            )
        }
        let offering = Offering(
            identifier: offeringId,
            serverDescription: "Test",
            metadata: [:],
            paywall: nil,
            availablePackages: packages,
            webCheckoutUrl: nil
        )
        let offerings = Offerings(
            offerings: [offeringId: offering],
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
        return WorkflowContext(
            workflow: workflow,
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

    static func makeWorkflow(
        singleStepFallbackId: String?,
        fallbackPackages: [PackageSpec],
        offeringId: String
    ) throws -> PublishedWorkflow {
        let fallbackIdJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""

        let terminalStepJSON: String
        let terminalScreenJSON: String
        if let fallbackId = singleStepFallbackId {
            terminalStepJSON = """
            "\(fallbackId)": { "id": "\(fallbackId)", "type": "screen", "screen_id": "screen_terminal" },
            """
            terminalScreenJSON = """
            "screen_terminal": \(makeScreenJSON(packages: fallbackPackages, offeringId: offeringId)),
            """
        } else {
            terminalStepJSON = ""
            terminalScreenJSON = ""
        }

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          \(fallbackIdJSON)
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen", "screen_id": "screen_initial" },
            \(terminalStepJSON)
            "step_placeholder": { "id": "step_placeholder", "type": "screen" }
          },
          "screens": {
            "screen_initial": \(makeScreenJSON(packages: [], offeringId: offeringId)),
            \(terminalScreenJSON)
            "screen_placeholder": \(makeScreenJSON(packages: [], offeringId: offeringId))
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

    static func makeScreenJSON(packages: [PackageSpec], offeringId: String) -> String {
        let componentsJSON = packages.map { packageComponentJSON(id: $0.id, isDefault: $0.isDefault) }
            .joined(separator: ",")
        return """
        {
            "template_name": "template_v2",
            "asset_base_url": "https://assets.pawwalls.com",
            "revision": 1,
            "default_locale": "en_US",
            "components_localizations": {},
            "offering_identifier": "\(offeringId)",
            "components_config": {
                "base": {
                    "stack": \(stackJSON(components: "[\(componentsJSON)]")),
                    "background": {
                        "type": "color",
                        "value": { "light": { "type": "hex", "value": "#220000ff" } }
                    }
                }
            }
        }
        """
    }

    static func packageComponentJSON(id: String, isDefault: Bool) -> String {
        return """
        {
            "type": "package",
            "packageId": "\(id)",
            "isSelectedByDefault": \(isDefault),
            "stack": \(stackJSON(components: "[]"))
        }
        """
    }

    static func stackJSON(components: String) -> String {
        return """
        {
            "type": "stack",
            "components": \(components),
            "dimension": {
                "type": "vertical",
                "alignment": "center",
                "distribution": "center"
            },
            "size": {
                "width": { "type": "fill" },
                "height": { "type": "fill" }
            },
            "margin": {},
            "padding": {},
            "spacing": 0
        }
        """
    }

}

#endif
