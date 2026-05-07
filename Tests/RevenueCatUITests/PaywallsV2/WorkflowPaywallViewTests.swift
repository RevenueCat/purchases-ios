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

// MARK: - workflowPackageContext tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testWorkflowPackageContextReturnsNilWhenNoFallbackStepId() throws {
        let context = try Self.makeContext(singleStepFallbackId: nil)
        expect(context.workflowPackageContext).to(beNil())
    }

    func testWorkflowPackageContextReturnsNilWhenSingleStepFallbackIdPointsToMissingStep() throws {
        let context = try Self.makeContext(singleStepFallbackId: "nonexistent_step")
        expect(context.workflowPackageContext).to(beNil())
    }

    func testWorkflowPackageContextReturnsIsSelectedByDefaultPackage() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: true)
            ]
        )
        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
        expect(context.workflowPackageContext?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testWorkflowPackageContextReturnsFirstPackageWhenNoneIsDefault() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: false)
            ]
        )
        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_monthly"
        expect(context.workflowPackageContext?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testWorkflowPackageContextReturnsNilForPackagelessWorkflowStep() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: []
        )
        expect(context.workflowPackageContext).to(beNil())
    }

}

// MARK: - Helpers for workflowPackageContext tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowPaywallViewTests {

    typealias PackageSpec = (id: String, isDefault: Bool)

    static func makeContext(
        singleStepFallbackId: String?,
        workflowPackages: [PackageSpec] = []
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let workflow = try makeWorkflow(
            singleStepFallbackId: singleStepFallbackId,
            workflowPackages: workflowPackages,
            offeringId: offeringId
        )
        let packages = workflowPackages.map { spec in
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
        workflowPackages: [PackageSpec],
        offeringId: String
    ) throws -> PublishedWorkflow {
        let workflowStepIdJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""

        let terminalStepJSON: String
        let terminalScreenJSON: String
        if let fallbackId = singleStepFallbackId {
            terminalStepJSON = """
            "\(fallbackId)": { "id": "\(fallbackId)", "type": "screen", "screen_id": "screen_terminal" },
            """
            terminalScreenJSON = """
            "screen_terminal": \(makeScreenJSON(packages: workflowPackages, offeringId: offeringId)),
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
          \(workflowStepIdJSON)
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
