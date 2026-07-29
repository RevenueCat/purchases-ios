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

    func testHasCompletedInSessionTrueAfterPurchase() {
        expect(WorkflowPaywallView.hasCompletedInSession(
            hasPurchasedInSession: true,
            hasCompletedWorkflowInSession: false
        )) == true
    }

    func testHasCompletedInSessionTrueAfterWorkflowCompletionSignal() {
        expect(WorkflowPaywallView.hasCompletedInSession(
            hasPurchasedInSession: false,
            hasCompletedWorkflowInSession: true
        )) == true
    }

    func testHasCompletedInSessionFalseAfterRestoreWithoutCompletionSignal() {
        // Raw restore success is not enough to complete a workflow. The presenter marks completion
        // only when restore actually dismisses the paywall.
        expect(WorkflowPaywallView.hasCompletedInSession(
            hasPurchasedInSession: false,
            hasCompletedWorkflowInSession: false
        )) == false
    }

    func testHasCompletedInSessionFalseWhenNeitherPurchasedNorRestored() {
        // Plain dismissal with nothing restored is an abandonment.
        expect(WorkflowPaywallView.hasCompletedInSession(
            hasPurchasedInSession: false,
            hasCompletedWorkflowInSession: false
        )) == false
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

    func testPageWorkflowPackageContextUsesScreenPackagesInsteadOfFallbackPackages() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_monthly", isDefault: true)],
            initialScreenJSON: Self.makeScreenJSON(
                packages: [(id: "$rc_annual", isDefault: true)],
                offeringId: "offering_test"
            )
        )
        let pagePackageContext = context.packageContext(for: "step_initial")

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_monthly"
        expect(pagePackageContext?.selectedPackage.identifier) == "$rc_annual"
        expect(pagePackageContext?.packages.map(\.identifier)) == ["$rc_annual"]
    }

    func testPageWorkflowPackageContextReturnsNilForPackagelessScreen() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_monthly", isDefault: true)]
        )

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_monthly"
        expect(context.packageContext(for: "step_initial")).to(beNil())
    }

}

// MARK: - packageContext(for:) via WorkflowContext

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testPackageContextForStepWithOwnPackagesReturnsStepLocalPackages() throws {
        // Package-bearing step: step has its own package components.
        // packageContext(for:) must return the step's own packages, not the workflow fallback.
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_monthly", isDefault: false), (id: "$rc_annual", isDefault: true)]
        )

        // step_terminal has the terminal screen with $rc_annual as default
        let result = context.packageContext(for: "step_terminal")

        expect(result?.selectedPackage.identifier) == "$rc_annual"
        expect(result?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testPackageContextForPackagelessStepReturnsNil() throws {
        // Packageless step: step_initial has no package components.
        // packageContext(for:) must return nil so callers can fall back to the workflow context.
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_annual", isDefault: true)]
        )

        // step_initial uses screen_initial which has no packages
        let result = context.packageContext(for: "step_initial")

        expect(result).to(beNil())
    }

    func testPackageContextForMissingStepReturnsNil() throws {
        let context = try Self.makeContext(singleStepFallbackId: nil)

        expect(context.packageContext(for: "nonexistent_step")).to(beNil())
    }

}

// MARK: - Step package context cache

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testPackageContextRemainsReferenceType() {
        func requiresReferenceType<T: AnyObject>(_: T.Type) {}

        requiresReferenceType(PackageContext.self)
    }

    func testCachedPackageContextMutationsPropagateThroughReference() {
        let cached = PackageContext(
            package: TestData.monthlyPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )
        let stepCache: [String: PackageContext] = ["step_terminal": cached]

        cached.package = TestData.annualPackage

        expect(stepCache["step_terminal"]?.package?.identifier) == TestData.annualPackage.identifier
    }

    /// Verifies that `buildPackageInput` carries the user's current selection forward when
    /// the preferred package exists in the next step's available packages.
    /// This is the forward-navigation path: user picks annual on step 1, navigates to step 2
    /// which also offers annual — step 2 should pre-select annual, not fall back to its own default.
    func testBuildPackageInputCarriesForwardPreferredPackageWhenAvailableInStep() throws {
        // step_terminal has annual (default) and monthly.
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_annual", isDefault: true), (id: "$rc_monthly", isDefault: false)]
        )
        let monthly = try XCTUnwrap(
            context.packageContext(for: "step_terminal")?.packages.first { $0.identifier == "$rc_monthly" }
        )

        let packageInput = WorkflowPaywallView.buildPackageInput(
            stepId: "step_terminal",
            context: context,
            preferredPackage: monthly,
            showZeroDecimalPlacePrices: false
        )

        expect(packageInput.packageContext.package?.identifier) == "$rc_monthly"
        expect(packageInput.effectiveWorkflowPackageContext?.selectedPackage.identifier) == "$rc_monthly"
        expect(packageInput.packageContext.variableContext.mostExpensivePricePerMonth).toNot(beNil())
    }

    /// Verifies that once a step's `PackageContext` is cached, subsequent navigations to that step
    /// reuse the cached instance (preserving any user mutations) rather than re-applying carry-forward.
    ///
    /// Scenario: user navigates step1 → step2 (annual carried forward), selects monthly on step2,
    /// returns to step1, then navigates forward to step2 again.
    /// Step2 must show monthly (the user's own previous selection), not annual (the new carry-forward).
    /// `WorkflowPaywallView.renderedPageForForwardNavigation` implements this via the cache-hit path that skips
    /// `buildPackageInput` entirely when the step already has a `PackageContext` in `stepPackageContexts`.
    ///
    /// This also guards that `PackageContext` is a reference type: the mutation at line
    /// `cachedCtx.package = monthly` must be visible through `stepCache` for the cache to work.
    func testCachedStepContextTakesPrecedenceOverCarryForwardOnRevisit() throws {
        let context = try Self.makeContext(
            singleStepFallbackId: "step_terminal",
            workflowPackages: [(id: "$rc_annual", isDefault: true), (id: "$rc_monthly", isDefault: false)]
        )
        let annual = try XCTUnwrap(
            context.packageContext(for: "step_terminal")?.packages.first { $0.identifier == "$rc_annual" }
        )
        let monthly = try XCTUnwrap(
            context.packageContext(for: "step_terminal")?.packages.first { $0.identifier == "$rc_monthly" }
        )

        // First forward navigation: annual carried forward → step gets annual.
        let cachedInput = WorkflowPaywallView.buildPackageInput(
            stepId: "step_terminal",
            context: context,
            preferredPackage: annual,
            showZeroDecimalPlacePrices: false
        )
        let cachedCtx = cachedInput.packageContext
        expect(cachedCtx.package?.identifier) == annual.identifier

        // User selects monthly on the step (mutation through the reference stored in stepPackageContexts).
        cachedCtx.package = monthly

        // Simulate the per-step cache that WorkflowPaywallView maintains.
        let stepCache: [String: PackageContext] = ["step_terminal": cachedCtx]

        // Second forward navigation would carry annual again — but the step is already cached.
        // WorkflowPaywallView.renderedPageForForwardNavigation takes the cache-hit path and skips buildPackageInput.
        // Demonstrate the divergence: carry-forward would produce annual, cache has monthly.
        let wouldBeWithCarryForward = WorkflowPaywallView.buildPackageInput(
            stepId: "step_terminal",
            context: context,
            preferredPackage: annual,
            showZeroDecimalPlacePrices: false
        )

        // Cache-hit path: user's own selection (monthly) is preserved.
        expect(stepCache["step_terminal"]?.package?.identifier) == monthly.identifier
        // Cache-miss path would have produced annual — confirming cache hit takes precedence.
        expect(wouldBeWithCarryForward.packageContext.package?.identifier) == annual.identifier
    }

    /// Verifies that `buildPackageInput` returns an empty `PackageContext` for a step that
    /// has no package components and no workflow fallback (nil `effectivePackageContext`).
    func testBuildPackageInputReturnsEmptyContextForPackagelessStepWithNoFallback() throws {
        // No singleStepFallbackId → no global workflow package context.
        let context = try Self.makeContext(singleStepFallbackId: nil)

        let packageInput = WorkflowPaywallView.buildPackageInput(
            stepId: "step_initial",
            context: context,
            preferredPackage: nil,
            showZeroDecimalPlacePrices: false
        )

        expect(packageInput.packageContext.package).to(beNil())
        expect(packageInput.effectiveWorkflowPackageContext).to(beNil())
        expect(packageInput.packageContext.variableContext.mostExpensivePricePerMonth).to(beNil())
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
        initialScreenJSON: String? = nil,
        terminalScreenJSON: String? = nil,
        extraOfferings: [Offering] = []
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let workflow = try makeWorkflow(
            singleStepFallbackId: singleStepFallbackId,
            workflowPackages: workflowPackages,
            initialScreenJSON: initialScreenJSON,
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
        var offeringsDict: [String: Offering] = [offeringId: offering]
        for extra in extraOfferings { offeringsDict[extra.identifier] = extra }
        let offerings = Offerings(
            offerings: offeringsDict,
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
            uiConfig: PreviewUIConfig.make(),
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

    static func makeWorkflow(
        singleStepFallbackId: String?,
        workflowPackages: [PackageSpec],
        initialScreenJSON customInitialScreenJSON: String? = nil,
        terminalScreenJSON customTerminalScreenJSON: String? = nil,
        offeringId: String
    ) throws -> PublishedWorkflow {
        let workflowStepIdJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""
        let initialScreenJSON = customInitialScreenJSON
            ?? makeScreenJSON(packages: [], offeringId: offeringId)

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
            "screen_initial": \(initialScreenJSON),
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

    static func makeScreenJSON(
        packages: [PackageSpec],
        offeringId: String,
        extraComponentsJSON: [String] = []
    ) -> String {
        let componentsJSON = (
            packages.map { packageComponentJSON(id: $0.id, isDefault: $0.isDefault) } + extraComponentsJSON
        ).joined(separator: ",")
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

// MARK: - exitOfferContext tests

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    func testExitOfferOfferingIsNotStepAware() throws {
        // context.exitOfferOffering returns non-nil whenever the exit offer is configured,
        // regardless of which step is current. The binding must therefore use
        // exitOfferContext(for:currentStepId:) so it is nil on non-triggering steps.
        let context = try Self.makeContextWithExitOffer(
            singleStepFallbackId: "step_terminal",
            exitOfferOfferingId: "exit_offering_a"
        )

        expect(context.exitOfferOffering).toNot(beNil())
        expect(WorkflowPaywallView.exitOfferContext(for: context, currentStepId: "step_initial")).to(beNil())
    }

    func testExitOfferContextReturnsNilWhenNotOnTriggeringStep() throws {
        let context = try Self.makeContextWithExitOffer(
            singleStepFallbackId: "step_terminal",
            exitOfferOfferingId: "exit_offering_a"
        )

        // step_initial != step_terminal → no exit offer
        let result = WorkflowPaywallView.exitOfferContext(for: context, currentStepId: "step_initial")

        expect(result).to(beNil())
    }

    func testExitOfferContextReturnsNilWhenNoExitOfferConfigured() throws {
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")

        let result = WorkflowPaywallView.exitOfferContext(for: context, currentStepId: "step_terminal")

        expect(result).to(beNil())
    }

    func testExitOfferContextReturnsContextWhenOnTriggeringStep() throws {
        let context = try Self.makeContextWithExitOffer(
            singleStepFallbackId: "step_terminal",
            exitOfferOfferingId: "exit_offering_a"
        )

        let result = WorkflowPaywallView.exitOfferContext(for: context, currentStepId: "step_terminal")

        expect(result?.exitOfferOffering.identifier) == "exit_offering_a"
    }

    private static func makeContextWithExitOffer(
        singleStepFallbackId: String,
        exitOfferOfferingId: String
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let baseJSON = Self.makeScreenJSON(packages: [], offeringId: offeringId)
        let screenJSON = String(baseJSON.dropLast()) + """
        , "exit_offers": { "dismiss": { "offering_id": "\(exitOfferOfferingId)" } }
        }
        """
        let exitOffering = Offering(
            identifier: exitOfferOfferingId,
            serverDescription: "Exit offering",
            metadata: [:],
            paywall: nil,
            availablePackages: [],
            webCheckoutUrl: nil
        )
        return try Self.makeContext(
            singleStepFallbackId: singleStepFallbackId,
            terminalScreenJSON: screenJSON,
            extraOfferings: [exitOffering]
        )
    }

}

#if !os(watchOS) && !os(macOS)

// MARK: - Callback tests (single step)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    @MainActor
    func testOnPurchaseStartedFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var packageBeingPurchased: Package?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseStarted { packageBeingPurchased = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(packageBeingPurchased).toEventuallyNot(beNil())
    }

    @MainActor
    func testOnPurchaseCompletedFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var customerInfo: CustomerInfo?

        // WorkflowPaywallView stores purchaseHandler as a plain `let` (no @ObservedObject),
        // so it relies on a parent observer to trigger re-renders when purchase state changes.
        // This wrapper mirrors what PaywallView does in production.
        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseCompleted { customerInfo = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    @MainActor
    func testOnPurchaseCancelledFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .cancelling()
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var cancelled = false

        let dispose = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseCancelled { cancelled = true }
            .addToHierarchy()

        defer { dispose() }

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(cancelled).toEventually(beTrue())
    }

    @MainActor
    func testOnPurchaseFailureFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .failing(Self.failureError)
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var error: NSError?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseFailure { error = $0 }
            .addToHierarchy()

        Task {
            _ = try? await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    @MainActor
    func testOnRestoreStartedFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var started = false

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreStarted { started = true }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.restorePurchases()
        }

        expect(started).toEventually(beTrue())
    }

    @MainActor
    func testOnRestoreCompletedFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var customerInfo: CustomerInfo?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreCompleted { customerInfo = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.restorePurchases()
            purchaseHandler.setRestored(TestData.customerInfo, success: false)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    @MainActor
    func testOnRestoreFailureFiredInWorkflow() throws {
        let purchaseHandler: PurchaseHandler = .failing(Self.failureError)
        let context = try Self.makeContext(singleStepFallbackId: "step_terminal")
        var error: NSError?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreFailure { error = $0 }
            .addToHierarchy()

        Task {
            _ = try? await purchaseHandler.restorePurchases()
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    private static let failureError: Error = ErrorCode.storeProblemError

}

// MARK: - Callback tests (non-initial step)
// These tests verify that purchase/restore callbacks fire when the workflow renders
// a non-initial step. WorkflowPaywallView uses a shared purchaseHandler across all
// steps — these tests confirm the callbacks are wired correctly regardless of step
// position. Navigation behavior itself is tested in WorkflowNavigator unit tests.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPaywallViewTests {

    @MainActor
    func testOnPurchaseStartedFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        // Start the workflow on step_b (a non-initial step) to verify callbacks
        // are wired on any step, not just the first one.
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var packageBeingPurchased: Package?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseStarted { packageBeingPurchased = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(packageBeingPurchased).toEventuallyNot(beNil())
    }

    @MainActor
    func testOnPurchaseCompletedFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var customerInfo: CustomerInfo?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseCompleted { customerInfo = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    @MainActor
    func testOnPurchaseCancelledFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .cancelling()
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var cancelled = false

        let dispose = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseCancelled { cancelled = true }
            .addToHierarchy()

        defer { dispose() }

        Task {
            _ = try await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(cancelled).toEventually(beTrue())
    }

    @MainActor
    func testOnPurchaseFailureFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .failing(Self.failureError)
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var error: NSError?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onPurchaseFailure { error = $0 }
            .addToHierarchy()

        Task {
            _ = try? await purchaseHandler.purchase(package: TestData.annualPackage)
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    @MainActor
    func testOnRestoreStartedFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var started = false

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreStarted { started = true }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.restorePurchases()
        }

        expect(started).toEventually(beTrue())
    }

    @MainActor
    func testOnRestoreCompletedFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .mock()
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var customerInfo: CustomerInfo?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreCompleted { customerInfo = $0 }
            .addToHierarchy()

        Task {
            _ = try await purchaseHandler.restorePurchases()
            purchaseHandler.setRestored(TestData.customerInfo, success: false)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    @MainActor
    func testOnRestoreFailureFiredFromNonInitialStep() throws {
        let purchaseHandler: PurchaseHandler = .failing(Self.failureError)
        let context = try Self.makeContextStartingAt(stepId: "step_b")
        var error: NSError?

        _ = try WorkflowPurchaseObserver(purchaseHandler: purchaseHandler, context: context)
            .onRestoreFailure { error = $0 }
            .addToHierarchy()

        Task {
            _ = try? await purchaseHandler.restorePurchases()
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

}

// MARK: - Callback test helpers

/// Mirrors the @StateObject role that PaywallView plays in production:
/// WorkflowPaywallView stores purchaseHandler as a plain `let`, so it needs
/// an observing parent to trigger re-renders when purchase state changes.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowPurchaseObserver: View {

    @ObservedObject var purchaseHandler: PurchaseHandler
    let context: WorkflowContext

    var body: some View {
        WorkflowPaywallView(
            context: context,
            purchaseHandler: purchaseHandler,
            introEligibilityChecker: .producing(eligibility: .eligible),
            showZeroDecimalPlacePrices: false,
            displayCloseButton: false,
            promoOfferCache: nil,
            onDismiss: {}
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowPaywallViewTests {

    /// Creates a two-step workflow (step_a, step_b) with initial_step_id set to stepId.
    /// Use this to exercise callbacks from a non-initial step without requiring navigation.
    static func makeContextStartingAt(stepId: String) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let workflowJSON = """
        {
          "id": "wf_non_initial_test",
          "display_name": "Non-Initial Test",
          "initial_step_id": "\(stepId)",
          "single_step_fallback_id": "step_a",
          "steps": {
            "step_a": { "id": "step_a", "type": "screen", "screen_id": "screen_a" },
            "step_b": { "id": "step_b", "type": "screen", "screen_id": "screen_b" }
          },
          "screens": {
            "screen_a": \(makeScreenJSON(packages: [], offeringId: offeringId)),
            "screen_b": \(makeScreenJSON(packages: [], offeringId: offeringId))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(workflowJSON.data(using: .utf8))
        let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)

        let packages = [
            makePackage(identifier: TestData.annualPackage.identifier, offeringId: offeringId),
            makePackage(identifier: TestData.monthlyPackage.identifier, offeringId: offeringId)
        ]
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
            uiConfig: PreviewUIConfig.make(),
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

}

// Note: callbacks are not re-tested across a live, in-flight step transition.
// WorkflowPaywallView holds a single `purchaseHandler` (a plain `let`) above the per-step
// PaywallsV2View subtrees that navigation swaps, so callback forwarding is step-independent
// by construction; the non-initial-step tests above already cover "fires from a step the
// view did not start on". Navigation/transition mechanics are covered by WorkflowNavigator
// and transition-state unit tests. Verifying callbacks during the animated two-page window
// needs UI automation (Maestro), not a unit-test seam.

// MARK: - Landscape safe area

#if canImport(UIKit)

/// A workflow paywall must paint to the horizontal screen edges in landscape, where the device
/// reports non-zero leading/trailing safe area insets (both are 0 in portrait). Rendering the same
/// screen through `PaywallsV2View` directly acts as the control.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowLandscapeSafeAreaTests: TestCase {

    /// iPhone 14 Pro Max landscape: 932x430pt, with a 21pt home indicator inset.
    fileprivate enum Landscape {
        static let size = CGSize(width: 932, height: 430)
        /// Both sides inset, as reported when the device symmetrizes the sensor housing.
        static let symmetricSafeArea = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)
        /// Only the sensor-housing side inset. Covered because a mask that merely widens and
        /// centers passes the symmetric case while still clipping half the inset here.
        static let asymmetricSafeArea = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 0)
        /// Non-zero top and bottom, to cover the vertical half of the mask growth.
        static let verticalSafeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    }

    /// The fixture screen's root background: `#220000ff`.
    fileprivate static let backgroundColor = PixelColor(red: 0x22, green: 0x00, blue: 0x00)

    /// The nested component fixture's own background: `#002200ff`, distinct from the root so the
    /// edge samples prove the component's background is what reached the edge.
    fileprivate static let nestedBackgroundColor = PixelColor(red: 0x00, green: 0x22, blue: 0x00)

    /// Sliding by only `size.width` leaves the off-screen page overlapping the clip mask, which shows
    /// it as a sliver in the horizontal safe-area strips for the length of the animation. Covers both
    /// roles and both directions: each is a separate call into the same production offset path. The
    /// animation itself is covered by the `open_workflow` / `navigate_workflow_back` Maestro flows.
    func testTransitionedPageSlidesFarEnoughToClearTheClipMask() {
        let directions: [WorkflowPageTransitionState<String>.Direction] = [.forward, .back]

        for safeArea in [Landscape.symmetricSafeArea, Landscape.asymmetricSafeArea] {
            for direction in directions {
                let geometry = Self.geometry(safeArea: safeArea)

                // The incoming page starts one full width out (progress 0); the outgoing page ends
                // one full width out (progress 1). Each is the moment that page is fully off-screen.
                var incoming = WorkflowPageTransitionState<String>(currentPage: "step_a")
                incoming.beginTransition(to: "step_b", direction: direction)

                var outgoing = incoming
                outgoing.advanceAnimation()

                let offsets = [
                    ("current", WorkflowPaywallView.pageOffset(
                        isHidden: false,
                        role: .current,
                        transitionState: incoming,
                        geometry: geometry
                    )),
                    ("outgoing", WorkflowPaywallView.pageOffset(
                        isHidden: false,
                        role: .outgoing,
                        transitionState: outgoing,
                        geometry: geometry
                    ))
                ]

                for (role, offset) in offsets {
                    expect(abs(offset)).to(
                        beGreaterThanOrEqualTo(geometry.screenWidth),
                        description: "\(role) page slid by \(offset) still overlaps the clip mask "
                            + "(direction \(direction), insets \(safeArea))"
                    )
                }
            }
        }
    }

    /// Ties the two coordinate spaces together: the safe-area box the pages are laid out in, plus the
    /// insets, must come back to the physical screen width that the mask spans.
    func testTransitionWidthIsTheFullScreenWidth() {
        for safeArea in [Landscape.symmetricSafeArea, Landscape.asymmetricSafeArea] {
            expect(Self.geometry(safeArea: safeArea).screenWidth) == Landscape.size.width
        }
    }

    func testParkedPageIsNotSlidOffScreen() {
        let geometry = Self.geometry(safeArea: Landscape.symmetricSafeArea)
        var transitionState = WorkflowPageTransitionState<String>(currentPage: "step_a")
        transitionState.beginTransition(to: "step_b", direction: .forward)

        let offset = WorkflowPaywallView.pageOffset(
            isHidden: true,
            role: .current,
            transitionState: transitionState,
            geometry: geometry
        )

        expect(offset) == 0
    }

    @MainActor
    func testWorkflowPageBackgroundReachesHorizontalScreenEdgesInLandscape() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderWorkflowInLandscape(safeArea: Landscape.symmetricSafeArea),
            axis: .horizontal,
            label: "workflow, symmetric insets"
        )
    }

    @MainActor
    func testWorkflowPageBackgroundReachesHorizontalScreenEdgesWithAsymmetricLandscapeInsets() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderWorkflowInLandscape(safeArea: Landscape.asymmetricSafeArea),
            axis: .horizontal,
            label: "workflow, asymmetric insets"
        )
    }

    /// A mid-animation frame: the page carries `isTransitioning`, which used to restrict background
    /// safe-area expansion to `.vertical` and left the horizontal strips unpainted for the length of
    /// every landscape transition.
    @MainActor
    func testWorkflowPageBackgroundReachesHorizontalScreenEdgesWhileTransitioning() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderScreenInLandscape(isTransitioning: true),
            axis: .horizontal,
            label: "workflow, mid-transition"
        )
    }

    /// `BackgroundStyleModifier` is shared with component-level views (stacks, text, badges), not
    /// just the page root, so pin a nested component background too: it must reach the horizontal
    /// edges mid-transition exactly as it does at rest, otherwise the paywall pops when the
    /// animation starts and ends.
    @MainActor
    func testComponentBackgroundReachesHorizontalScreenEdgesWhileTransitioning() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderScreenInLandscape(
                isTransitioning: true,
                screenJSON: Self.nestedComponentBackgroundScreenJSON(),
                settled: Self.nestedBackgroundColor
            ),
            axis: .horizontal,
            label: "nested component background, mid-transition",
            expected: Self.nestedBackgroundColor
        )
    }

    /// `transitionClipMask` grows the mask on all four edges, and the vertical half of that is
    /// pre-existing behavior the rewrite to per-edge padding had to preserve. The other tests use a
    /// zero top inset and sample the middle row, so they would not notice a vertical regression.
    @MainActor
    func testWorkflowPageBackgroundReachesVerticalScreenEdges() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderWorkflowInLandscape(safeArea: Landscape.verticalSafeArea),
            axis: .vertical,
            label: "workflow, vertical insets"
        )
    }

    /// Control: the same screen without the workflow container, so a difference in the tests above
    /// belongs to the container rather than to the V2 renderer.
    @MainActor
    func testLegacyPaywallBackgroundReachesHorizontalScreenEdgesInLandscape() throws {
        try Self.expectBackgroundAtEdges(
            of: try Self.renderScreenInLandscape(isTransitioning: false),
            axis: .horizontal,
            label: "legacy"
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowLandscapeSafeAreaTests {

    enum Axis {
        case horizontal
        case vertical

        var edgeNames: (String, String) {
            switch self {
            case .horizontal: return ("left", "right")
            case .vertical: return ("top", "bottom")
            }
        }
    }

    /// Samples the two opposite edges of `axis` at the cross-axis midpoint. Both must be the
    /// paywall's background: anything else means it was clipped to, or laid out inside, the safe
    /// area, exposing whatever is presenting it.
    static func expectBackgroundAtEdges(
        of image: UIImage,
        axis: Axis,
        label: String,
        expected: PixelColor = WorkflowLandscapeSafeAreaTests.backgroundColor
    ) throws {
        let pixels = try PixelSampler(image: image)
        let midColumn = pixels.width / 2
        let midRow = pixels.height / 2

        let (first, second): (PixelColor, PixelColor)
        switch axis {
        case .horizontal:
            first = try pixels.color(column: 0, row: midRow)
            second = try pixels.color(column: pixels.width - 1, row: midRow)
        case .vertical:
            first = try pixels.color(column: midColumn, row: 0)
            second = try pixels.color(column: midColumn, row: pixels.height - 1)
        }

        let (firstName, secondName) = axis.edgeNames
        for (edge, color) in [(firstName, first), (secondName, second)] {
            expect(color).to(
                equal(expected),
                description: "\(label): \(edge) edge pixel is \(color), expected the paywall "
                    + "background \(expected). It does not reach the \(edge) screen edge."
            )
        }
    }

    /// Models what the production `GeometryReader` reports: `size` is the safe-area box, not the
    /// screen, so the insets have to come off it. Building this with the full screen size would
    /// inflate `screenWidth` past the device and validate a slide distance no device asks for.
    static func geometry(safeArea: UIEdgeInsets) -> WorkflowTransitionGeometry {
        return .init(
            size: CGSize(
                width: Landscape.size.width - safeArea.left - safeArea.right,
                height: Landscape.size.height - safeArea.top - safeArea.bottom
            ),
            safeAreaInsets: EdgeInsets(
                top: safeArea.top,
                leading: safeArea.left,
                bottom: safeArea.bottom,
                trailing: safeArea.right
            )
        )
    }

    /// The fixture screen rendered without the workflow container, optionally carrying the workflow
    /// transition flag so a mid-animation frame can be sampled.
    @MainActor
    static func renderScreenInLandscape(
        isTransitioning: Bool,
        screenJSON: String? = nil,
        settled: PixelColor = WorkflowLandscapeSafeAreaTests.backgroundColor
    ) throws -> UIImage {
        let context = try Self.makeLandscapeContext(screenJSON: screenJSON)
        let screen = try XCTUnwrap(context.workflow.screens[Self.landscapeScreenId])
        let offering = try XCTUnwrap(context.offering(for: screen.offeringIdentifier))

        return try Self.renderInLandscape(
            PaywallsV2View(
                paywallComponents: WorkflowScreenMapper.toPaywallComponents(
                    screen: screen,
                    uiConfig: context.uiConfig
                ),
                offering: offering,
                purchaseHandler: .mock(),
                introEligibilityChecker: .producing(eligibility: .eligible),
                showZeroDecimalPlacePrices: false,
                onDismiss: {},
                failedToLoadFont: { _ in },
                colorScheme: .light
            )
            .environment(
                \.workflowRenderingContext,
                WorkflowRenderingContext(
                    pageTransition: .init(
                        pageOffset: 0,
                        headerButtonOpacity: 1,
                        isTransitioning: isTransitioning
                    )
                )
            ),
            safeArea: Landscape.symmetricSafeArea,
            settled: settled
        )
    }

    @MainActor
    static func renderWorkflowInLandscape(safeArea: UIEdgeInsets) throws -> UIImage {
        let context = try Self.makeLandscapeContext()

        return try Self.renderInLandscape(
            WorkflowPaywallView(
                context: context,
                purchaseHandler: .mock(),
                introEligibilityChecker: .producing(eligibility: .eligible),
                showZeroDecimalPlacePrices: false,
                displayCloseButton: false,
                promoOfferCache: nil,
                onDismiss: {}
            ),
            safeArea: safeArea
        )
    }

    /// Hosts `view` in a landscape-sized window carrying the given safe area insets and rasterizes
    /// it at scale 1 so pixel coordinates map to points.
    @MainActor
    static func renderInLandscape(
        _ view: some View,
        safeArea: UIEdgeInsets,
        settled: PixelColor = WorkflowLandscapeSafeAreaTests.backgroundColor
    ) throws -> UIImage {
        UIView.setAnimationsEnabled(false)

        let controller = UIHostingController(rootView: view)
        controller.additionalSafeAreaInsets = safeArea
        // A white host stands in for the presenting surface, so any region the paywall fails to
        // cover reads as white rather than as an ambiguous transparent pixel.
        controller.view.backgroundColor = .white

        // This target has no host application, so there is no scene to attach to. That is fine for
        // `layer.render(in:)`, which does not need the window on screen.
        let window = UIWindow(frame: .init(origin: .zero, size: Landscape.size))
        window.isHidden = false
        window.backgroundColor = .white
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.frame = window.bounds
        window.setNeedsLayout()
        window.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let render = {
            // `layer.render(in:)` rather than `drawHierarchy(in:afterScreenUpdates:)`: the latter
            // needs the window genuinely on screen and yields an all-black image under XCTest.
            UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
                window.layer.render(in: context.cgContext)
            }
        }

        // Pump the runloop until the paywall has drawn, rather than sleeping a fixed interval:
        // state resolution and layout usually settle in a few frames.
        var image = render()
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline,
              (try? PixelSampler(image: image).color(
                  column: Int(Landscape.size.width / 2),
                  row: Int(Landscape.size.height / 2)
              )) != settled {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            image = render()
        }

        window.rootViewController = nil
        window.resignKey()
        window.isHidden = true

        return image
    }

    /// Matches the screen id `makeContext` gives the workflow's initial step.
    static let landscapeScreenId = "screen_initial"
    static let landscapeOfferingId = "offering_test"

    /// The landscape fixture: a workflow whose initial screen is `screenJSON`, defaulting to the
    /// flat `#220000ff` fill/fill stack that makes edge pixels trivial to sample.
    static func makeLandscapeContext(screenJSON: String? = nil) throws -> WorkflowContext {
        return try WorkflowPaywallViewTests.makeContext(
            singleStepFallbackId: nil,
            initialScreenJSON: screenJSON
        )
    }

    /// The flat fixture plus a fill/fill child stack carrying its own `#002200ff` background, so the
    /// sampled edges belong to a component background rather than the page root.
    static func nestedComponentBackgroundScreenJSON() -> String {
        let childStack = """
        {
            "type": "stack",
            "components": [],
            "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
            "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
            "margin": {},
            "padding": {},
            "spacing": 0,
            "background": {
                "type": "color",
                "value": { "light": { "type": "hex", "value": "#002200ff" } }
            }
        }
        """

        return WorkflowPaywallViewTests.makeScreenJSON(
            packages: [],
            offeringId: Self.landscapeOfferingId,
            extraComponentsJSON: [childStack]
        )
    }

}

private struct PixelColor: Equatable, CustomStringConvertible {

    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var description: String {
        return String(format: "#%02X%02X%02X", self.red, self.green, self.blue)
    }

}

/// Reads back the raw pixels of a rendered image so individual coordinates can be asserted on.
private struct PixelSampler {

    let width: Int
    let height: Int

    private let bytesPerRow: Int
    private let bytes: [UInt8]

    init(image: UIImage) throws {
        let cgImage = try XCTUnwrap(image.cgImage)
        self.width = cgImage.width
        self.height = cgImage.height
        self.bytesPerRow = cgImage.width * 4

        var buffer = [UInt8](repeating: 0, count: cgImage.width * 4 * cgImage.height)
        let context = try XCTUnwrap(
            CGContext(
                data: &buffer,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: cgImage.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(
            cgImage,
            in: .init(origin: .zero, size: .init(width: cgImage.width, height: cgImage.height))
        )
        self.bytes = buffer
    }

    func color(column: Int, row: Int) throws -> PixelColor {
        guard column >= 0, column < self.width, row >= 0, row < self.height else {
            throw XCTSkip("Pixel (\(column), \(row)) is outside the \(self.width)x\(self.height) render.")
        }

        let offset = row * self.bytesPerRow + column * 4
        return .init(
            red: self.bytes[offset],
            green: self.bytes[offset + 1],
            blue: self.bytes[offset + 2]
        )
    }

}

#endif // canImport(UIKit)

#endif // !os(watchOS) && !os(macOS)

#endif
