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
import SwiftUI
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

    func testWorkflowPackageOverridePrefersWorkflowValueOverPageDefault() {
        let defaultPackage = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.annualPackage
        )

        expect(defaultPackage?.identifier) == TestData.annualPackage.identifier
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

    func testWorkflowPackageContextReturnsDefaultPackageInsideStickyFooter() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            terminalScreenJSON: Self.makeStickyFooterScreenJSON(
                packages: [(id: "$rc_annual", isDefault: true)],
                offeringId: "offering_test"
            )
        )

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
        expect(context.workflowPackageContext?.packages.map(\.identifier)) == ["$rc_annual"]
    }

    func testWorkflowPackageContextReturnsDefaultPackageInsideTabsCarousel() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            terminalScreenJSON: Self.makeTabsCarouselScreenJSON(
                packageID: "$rc_weekly",
                offeringId: "offering_test"
            )
        )

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_weekly"
        expect(context.workflowPackageContext?.packages.map(\.identifier)) == ["$rc_weekly"]
    }

}

// MARK: - variableContext population tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testWorkflowPackageContextPopulatesVariableContextForPricingVariables() async throws {
        // A packageless screen starts with an empty variableContext.
        // Before the fix, only `package` was set from workflowPackageContext;
        // `variableContext` stayed empty, so {{ product.relative_discount }} always resolved to "".
        let packageContext = PackageContext(
            package: nil,
            variableContext: .init(packages: [], showZeroDecimalPlacePrices: true)
        )
        expect(packageContext.variableContext.mostExpensivePricePerMonth).to(beNil())

        // Verify that calling update() with a WorkflowPackageContext populates both fields.
        let package = TestData.monthlyPackage
        let workflowCtx = WorkflowPackageContext(selectedPackage: package, packages: [package])
        await packageContext.update(
            package: workflowCtx.selectedPackage,
            variableContext: .init(
                packages: workflowCtx.packages,
                showZeroDecimalPlacePrices: true
            )
        )

        // Both package and variableContext must be set for all price variables to resolve correctly.
        expect(packageContext.package?.identifier) == package.identifier
        expect(packageContext.variableContext.mostExpensivePricePerMonth).toNot(beNil())
    }

}

// MARK: - Helpers for workflowPackageContext tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowPaywallViewTests {

    typealias PackageSpec = (id: String, isDefault: Bool)

    static func makeContext(
        singleStepFallbackId: String?,
        workflowPackages: [PackageSpec] = [],
        terminalScreenJSON: String? = nil
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let workflow = try makeWorkflow(
            singleStepFallbackId: singleStepFallbackId,
            workflowPackages: workflowPackages,
            terminalScreenJSON: terminalScreenJSON,
            offeringId: offeringId
        )
        let packageIdentifiers = Set(workflowPackages.map(\.id)).union([
            TestData.monthlyPackage.identifier,
            TestData.annualPackage.identifier,
            TestData.weeklyPackage.identifier
        ])
        let packages = packageIdentifiers.map { Self.makePackage(identifier: $0, offeringId: offeringId) }
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
        terminalScreenJSON customTerminalScreenJSON: String? = nil,
        offeringId: String
    ) throws -> PublishedWorkflow {
        let workflowStepIdJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""

        let terminalStepJSON: String
        let terminalScreenJSON: String
        if let fallbackId = singleStepFallbackId {
            terminalStepJSON = """
            "\(fallbackId)": { "id": "\(fallbackId)", "type": "screen", "screen_id": "screen_terminal" },
            """
            let screenJSON = customTerminalScreenJSON
                ?? makeScreenJSON(packages: workflowPackages, offeringId: offeringId)
            terminalScreenJSON = """
            "screen_terminal": \(screenJSON),
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

    static func makeStickyFooterScreenJSON(
        packages: [PackageSpec],
        offeringId: String
    ) -> String {
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
                    "stack": \(stackJSON(components: "[]")),
                    "sticky_footer": {
                        "type": "sticky_footer",
                        "stack": \(stackJSON(components: "[\(componentsJSON)]"))
                    },
                    "background": {
                        "type": "color",
                        "value": { "light": { "type": "hex", "value": "#220000ff" } }
                    }
                }
            }
        }
        """
    }

    static func makeTabsCarouselScreenJSON(
        packageID: String,
        offeringId: String
    ) -> String {
        let packageJSON = packageComponentJSON(id: packageID, isDefault: true)
        let tabControlComponentsJSON = """
        [
            {
                "type": "tab_control_button",
                "tab_id": "tab_1",
                "stack": \(stackJSON(components: "[]"))
            }
        ]
        """
        let tabControlStackJSON = stackJSON(components: tabControlComponentsJSON)
        let tabStackJSON = stackJSON(components: """
        [
            {
                "type": "carousel",
                "page_alignment": "center",
                "page_spacing": 0,
                "page_peek": 20,
                "initial_page_index": 0,
                "loop": false,
                "pages": [
                    \(stackJSON(components: "[\(packageJSON)]"))
                ]
            }
        ]
        """)
        let rootStackJSON = stackJSON(components: """
        [
            {
                "type": "tabs",
                "control": {
                    "type": "buttons",
                    "stack": \(tabControlStackJSON)
                },
                "tabs": [
                    {
                        "id": "tab_1",
                        "stack": \(tabStackJSON)
                    }
                ],
                "default_tab_id": "tab_1",
                "visible": true,
                "size": {
                    "width": { "type": "fill" },
                    "height": { "type": "fill" }
                },
                "padding": {},
                "margin": {}
            }
        ]
        """)

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
                    "stack": \(rootStackJSON),
                    "background": {
                        "type": "color",
                        "value": { "light": { "type": "hex", "value": "#220000ff" } }
                    }
                }
            }
        }
        """
    }

    static func makePackage(identifier: String, offeringId: String) -> Package {
        let sourcePackage: Package

        switch identifier {
        case TestData.annualPackage.identifier:
            sourcePackage = TestData.annualPackage
        case TestData.weeklyPackage.identifier:
            sourcePackage = TestData.weeklyPackage
        default:
            sourcePackage = TestData.monthlyPackage
        }

        return Package(
            identifier: identifier,
            packageType: .custom,
            storeProduct: sourcePackage.storeProduct,
            offeringIdentifier: offeringId,
            webCheckoutUrl: nil
        )
    }

}

#endif
