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
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
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

    func testOfferingForInitialIdentifierReturnsInitialOfferingWithPresentedContext() throws {
        let presentedOfferingContext = Self.makePresentedOfferingContext()
        let initialOffering = Self.makeOffering(identifier: "offering_a")
            .withPresentedOfferingContext(presentedOfferingContext)
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([initialOffering]),
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )

        let resolvedOffering = try XCTUnwrap(context.offering(for: initialOffering.identifier))
        let packageContext = try XCTUnwrap(resolvedOffering.availablePackages.first?.presentedOfferingContext)

        expect(packageContext.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(packageContext.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(packageContext.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(packageContext.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId
    }

    func testOfferingForStepOfferingPreservesPresentedOfferingContext() throws {
        let presentedOfferingContext = Self.makePresentedOfferingContext()
        let initialOffering = Self.makeOffering(identifier: "offering_a")
            .withPresentedOfferingContext(presentedOfferingContext)
        let stepOffering = Self.makeOffering(identifier: "offering_b")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([initialOffering, stepOffering]),
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )

        let resolvedOffering = try XCTUnwrap(context.offering(for: stepOffering.identifier))
        let packageContext = try XCTUnwrap(resolvedOffering.availablePackages.first?.presentedOfferingContext)

        expect(packageContext.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(packageContext.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(packageContext.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(packageContext.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId
    }

    func testOfferingForMissingIdentifierReturnsNil() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([offering]),
            initialOffering: offering,
            presentedOfferingContext: Self.makePresentedOfferingContext()
        )

        expect(context.offering(for: "offering_missing")).to(beNil())
    }

    // MARK: - packageContext(for:)

    func testPackageContextForStepWithPackagesReturnsSelectedByDefaultPackage() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: true)
            ]
        )

        let result = context.packageContext(for: "step_terminal")

        expect(result?.selectedPackage.identifier) == "$rc_annual"
        expect(result?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testPackageContextForStepWithPackagesReturnsFirstWhenNoneIsDefault() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: false)
            ]
        )

        let result = context.packageContext(for: "step_terminal")

        expect(result?.selectedPackage.identifier) == "$rc_monthly"
    }

    func testPackageContextForPackagelessStepReturnsNil() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: []
        )

        expect(context.packageContext(for: "step_terminal")).to(beNil())
    }

    func testPackageContextForMissingStepReturnsNil() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)]
        )

        expect(context.packageContext(for: "step_missing")).to(beNil())
    }

    func testWorkflowPackageContextDelegatesToPackageContextForFallbackStep() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)],
            singleStepFallbackId: "step_terminal"
        )

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
        expect(context.packageContext(for: "step_terminal")?.selectedPackage.identifier) == "$rc_annual"
    }

    // MARK: - Sheet packages and relative discounts

    @MainActor
    func testRelativeDiscountIncludesPackagesInViewAllPlansSheet() throws {
        let context = try Self.makeSheetContext()
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "paywall", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        )

        expect(input.packageContext.package?.identifier) == "$rc_annual"
        expect(input.packageContext.variableContext.mostExpensivePricePerMonth) == 14.99
        expect(try Self.discountText(context: input.packageContext)) == "56%"
    }

    @MainActor
    func testPackagelessStepInheritsDiscountBaselineFromSheet() throws {
        let context = try Self.makeSheetContext()
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "intro", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        )

        expect(try Self.discountText(context: input.packageContext)) == "56%"
    }

    @MainActor
    func testSheetDefaultDoesNotOverridePageDefault() throws {
        let context = try Self.makeSheetContext(footer: [
            Self.sheetButton([.stack(.init(components: [Self.packageComponent("$rc_monthly", isDefault: true)]))]),
            Self.packageComponent("$rc_annual", isDefault: true)
        ])
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "paywall", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        )

        expect(input.packageContext.package?.identifier) == "$rc_annual"
        expect(try Self.discountText(context: input.packageContext)) == "56%"
    }

    func testSheetDefaultDoesNotOverrideFirstPagePackageWhenPageHasNoDefault() throws {
        let context = try Self.makeSheetContext(footer: [
            Self.sheetButton([Self.packageComponent("$rc_monthly", isDefault: true)]),
            Self.packageComponent("$rc_annual")
        ])

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
    }

    @MainActor
    func testSheetOnlyPaywallUsesSheetDefaultAndDiscountBaseline() throws {
        let context = try Self.makeSheetContext(footer: [
            Self.sheetButton([
                Self.packageComponent("$rc_monthly"),
                Self.packageComponent("$rc_annual", isDefault: true)
            ])
        ])
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "paywall", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        )

        expect(input.packageContext.package?.identifier) == "$rc_annual"
        expect(try Self.discountText(context: input.packageContext)) == "56%"
    }

    @MainActor
    func testPreferredMonthlySheetPackageHasNoRelativeDiscount() throws {
        let context = try Self.makeSheetContext()
        let monthly = try XCTUnwrap(context.initialOffering.monthly)
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "intro", context: context, preferredPackage: monthly, showZeroDecimalPlacePrices: true
        )

        expect(input.packageContext.package?.identifier) == "$rc_monthly"
        expect(try Self.discountText(context: input.packageContext)) == ""
    }

    func testCollectsSheetInsidePackageStack() throws {
        let annual = Self.packageComponent(
            "$rc_annual", isDefault: true, children: [Self.sheetButton([Self.packageComponent("$rc_monthly")])]
        )
        let context = try Self.makeSheetContext(footer: [annual])

        expect(context.packageContext(for: "paywall")?.packages.map(\.identifier))
            .to(contain("$rc_annual", "$rc_monthly"))
        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
    }

    func testDuplicateSheetPackagePreservesFirstPromoOfferCode() throws {
        let context = try Self.makeSheetContext(footer: [
            Self.packageComponent("$rc_annual", isDefault: true, promoCode: "annual_promo"),
            Self.sheetButton([Self.packageComponent("$rc_annual", promoCode: "sheet_promo")])
        ])

        expect(context.packageContext(for: "paywall")?.promoOfferCodesByPackageId["$rc_annual"]) == "annual_promo"
    }

    func testDuplicateSheetPackageFillsMissingPromoOfferCode() throws {
        let context = try Self.makeSheetContext(footer: [
            Self.packageComponent("$rc_annual", isDefault: true),
            Self.sheetButton([Self.packageComponent("$rc_annual", promoCode: "sheet_promo")])
        ])

        expect(context.packageContext(for: "paywall")?.promoOfferCodesByPackageId["$rc_annual"]) == "sheet_promo"
    }

    func testCollectsPackagesInButtonContentWithoutSheetDestination() throws {
        let button = PaywallComponent.button(.init(
            action: .navigateBack,
            stack: .init(components: [Self.packageComponent("$rc_monthly", isDefault: true)])
        ))
        let context = try Self.makeSheetContext(footer: [button])

        expect(context.workflowPackageContext?.packages.map(\.identifier)) == ["$rc_monthly"]
    }

    func testCollectsPackagesInHeader() throws {
        let context = try Self.makeSheetContext(
            footer: [Self.packageComponent("$rc_annual", isDefault: true)],
            header: .init(stack: .init(components: [Self.packageComponent("$rc_monthly")]))
        )

        expect(context.workflowPackageContext?.packages.map(\.identifier)).to(contain("$rc_monthly", "$rc_annual"))
        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
    }

    @MainActor
    func testAnnualOnlyPaywallDoesNotUseUnshownOfferingPackagesForDiscount() throws {
        let context = try Self.makeSheetContext(footer: [Self.packageComponent("$rc_annual", isDefault: true)])
        let input = WorkflowPaywallView.buildPackageInput(
            stepId: "paywall", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        )

        expect(input.effectiveWorkflowPackageContext?.packages.map(\.identifier)) == ["$rc_annual"]
        expect(try Self.discountText(context: input.packageContext)) == ""
    }

    // MARK: - effectivePackageContext(for:preferring: nil)

    func testEffectivePackageContextForPackageBearingStepUsesStepContextNotGlobalFallback() throws {
        // Workflow: global fallback = annual (step_fallback), step_own has monthly + weekly.
        // effectivePackageContext for step_own must return monthly — the step's own default —
        // not annual (the global fallback).
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_weekly", isDefault: false)]
        )

        let effective = context.effectivePackageContext(for: "step_own", preferring: nil)

        expect(effective?.selectedPackage.identifier) == "$rc_monthly"
        expect(effective?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_weekly"]
    }

    func testEffectivePackageContextForPackagelessStepFallsBackToGlobalWorkflowContext() throws {
        // Packageless step (step_initial) has no package components.
        // effectivePackageContext must return the global fallback (annual).
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: []
        )

        let effective = context.effectivePackageContext(for: "step_own", preferring: nil)

        expect(effective?.selectedPackage.identifier) == "$rc_annual"
    }

    func testEffectivePackageContextReturnsNilWhenNoPackagesAnywhere() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: []
        )

        expect(context.effectivePackageContext(for: "step_terminal", preferring: nil)).to(beNil())
        expect(context.effectivePackageContext(for: "step_initial", preferring: nil)).to(beNil())
    }

    func testEffectivePackageContextForFallbackStepMatchesWorkflowPackageContext() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)],
            singleStepFallbackId: "step_terminal"
        )

        let effective = context.effectivePackageContext(for: "step_terminal", preferring: nil)

        expect(effective?.selectedPackage.identifier) == context.workflowPackageContext?.selectedPackage.identifier
    }

    // MARK: - effectivePackageContext(for:preferring:)

    func testEffectivePackageContextPreferredPackageSelectedWhenAvailableInStep() throws {
        // step_own has [monthly (default), weekly]. Preferred = weekly.
        // weekly IS in step_own → should be selected.
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_weekly", isDefault: false)]
        )
        let weekly = try XCTUnwrap(
            context.packageContext(for: "step_own")?.packages.first(where: { $0.identifier == "$rc_weekly" })
        )

        let result = context.effectivePackageContext(for: "step_own", preferring: weekly)

        expect(result?.selectedPackage.identifier) == "$rc_weekly"
        expect(result?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_weekly"]
    }

    func testEffectivePackageContextPreferredNotInStepFallsBackToWorkflowDefault() throws {
        // step_own has [monthly, annual]. Global fallback default = annual.
        // step_fallback has [annual (default), weekly].
        // Preferred = weekly (NOT in step_own). Workflow default (annual) IS in step_own → use annual.
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true), (id: "$rc_weekly", isDefault: false)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_annual", isDefault: false)]
        )
        let weekly = try XCTUnwrap(
            context.workflowPackageContext?.packages.first(where: { $0.identifier == "$rc_weekly" })
        )

        let result = context.effectivePackageContext(for: "step_own", preferring: weekly)

        expect(result?.selectedPackage.identifier) == "$rc_annual"
        expect(result?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testEffectivePackageContextNilPreferredReturnsStepOwnDefault() throws {
        // No carry-forward (nil preferred) → use the step's own isSelectedByDefault.
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_weekly", isDefault: false)]
        )

        let result = context.effectivePackageContext(for: "step_own", preferring: nil)

        expect(result?.selectedPackage.identifier) == "$rc_monthly"
    }

    func testEffectivePackageContextPreferredCarriedThroughPackagelessStep() throws {
        // step_own has no package components → falls back to workflowPackageContext.
        // workflowPackageContext has [annual (default), monthly].
        // Preferred = monthly (IS in the workflow context's packages) → should be selected.
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true), (id: "$rc_monthly", isDefault: false)],
            ownStepPackages: []
        )
        let monthly = try XCTUnwrap(
            context.workflowPackageContext?.packages.first(where: { $0.identifier == "$rc_monthly" })
        )

        let result = context.effectivePackageContext(for: "step_own", preferring: monthly)

        expect(result?.selectedPackage.identifier) == "$rc_monthly"
    }

    func testEffectivePackageContextPreferredNotInStepAndNoWorkflowDefaultFallsBackToStepDefault() throws {
        // step_own has [monthly (default), weekly]. Global fallback has [annual].
        // annual is NOT in step_own. Preferred = annual (not in step_own, wfDefault = annual also not in step_own).
        // Last resort: step_own's own default (monthly).
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_weekly", isDefault: false)]
        )
        let annual = try XCTUnwrap(
            context.workflowPackageContext?.selectedPackage
        )

        let result = context.effectivePackageContext(for: "step_own", preferring: annual)

        expect(result?.selectedPackage.identifier) == "$rc_monthly"
    }

    func testEffectivePackageContextPreferringCarryForwardSelectsDestinationOfferingsPackage() throws {
        // Multi-offering: step_fallback uses "offering_a", step_own uses "offering_b".
        // Both expose $rc_monthly — same identifier but different Package objects from different offerings.
        // Carry-forward must return the $rc_monthly from offering_b (the destination step),
        // not offering_a's instance (the source).
        let context = try Self.makeWorkflowContextWithMultiOfferingSteps(
            fallbackOfferingId: "offering_a",
            fallbackPackages: [(id: "$rc_monthly", isDefault: true)],
            ownOfferingId: "offering_b",
            ownPackages: [(id: "$rc_monthly", isDefault: true)]
        )
        let monthlyFromFallback = try XCTUnwrap(
            context.packageContext(for: "step_fallback")?.selectedPackage
        )
        expect(monthlyFromFallback.offeringIdentifier) == "offering_a"

        let result = try XCTUnwrap(
            context.effectivePackageContext(for: "step_own", preferring: monthlyFromFallback)
        )

        expect(result.selectedPackage.identifier) == "$rc_monthly"
        expect(result.selectedPackage.offeringIdentifier) == "offering_b"
    }

    func testEffectivePackageContextWorkflowDefaultFallbackSelectsDestinationOfferingsPackage() throws {
        // Multi-offering: step_fallback (offering_a) has [annual (default), weekly].
        //                 step_own    (offering_b) has [annual, monthly].
        // Preferred = weekly (not in step_own) → triggers the wfDefault path (lines 99-101).
        // wfDefault = annual from offering_a IS present in step_own by identifier.
        // Result must use annual from offering_b, not offering_a's instance.
        let context = try Self.makeWorkflowContextWithMultiOfferingSteps(
            fallbackOfferingId: "offering_a",
            fallbackPackages: [(id: "$rc_annual", isDefault: true), (id: "$rc_weekly", isDefault: false)],
            ownOfferingId: "offering_b",
            ownPackages: [(id: "$rc_annual", isDefault: false), (id: "$rc_monthly", isDefault: true)]
        )
        let weeklyFromFallback = try XCTUnwrap(
            context.packageContext(for: "step_fallback")?.packages.first { $0.identifier == "$rc_weekly" }
        )

        let result = try XCTUnwrap(
            context.effectivePackageContext(for: "step_own", preferring: weeklyFromFallback)
        )

        expect(result.selectedPackage.identifier) == "$rc_annual"
        expect(result.selectedPackage.offeringIdentifier) == "offering_b"
    }

    // MARK: - exitOfferOfferingId

    func testExitOfferOfferingReturnsNilWhenNoSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenFallbackStepHasNoExitOffers() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithSingleStepFallback(singleStepFallbackId: "step_1"),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenExitOfferingNotInAllOfferings() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings(offering),  // exit offering not included
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenSameAsCurrentOffering() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "offering_a"  // same as initial offering
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsOfferingWhenConfiguredAndAvailable() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let exitOffering = Self.makeOffering(identifier: "exit_offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings([offering, exitOffering]),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering?.identifier) == "exit_offering_a"
    }

    // MARK: - exitOfferOffering (multi-page)

    func testExitOfferOfferingReturnsNilForMultiPageWorkflowWithNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilForMultiPageWorkflowWithoutSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let exitOffering = Self.makeOffering(identifier: "exit_offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeMultiPageWorkflowWithExitOffer(
                exitOfferOfferingId: "exit_offering_a",
                onStepId: "step_2"
            ),
            allOfferings: Self.makeOfferings([offering, exitOffering]),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        // No singleStepFallbackId — exit offer is not resolved (mirrors Android's dismissExitOffer).
        expect(context.exitOfferOffering).to(beNil())
    }

    // MARK: - exitOfferTriggeringStepId

    func testExitOfferTriggeringStepIdReturnsNilWhenNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

    func testExitOfferTriggeringStepIdReturnsNilWhenFallbackStepHasNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithSingleStepFallback(singleStepFallbackId: "step_1"),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

    func testExitOfferTriggeringStepIdReturnsSingleStepFallbackIdWhenExitOfferIsConfigured() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId) == "step_1"
    }

    func testExitOfferTriggeringStepIdReturnsNilForMultiPageWorkflowWithoutSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeMultiPageWorkflowWithExitOffer(
                exitOfferOfferingId: "exit_offering_a",
                onStepId: "step_2"
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        // No singleStepFallbackId — triggering step is not resolved (mirrors Android's dismissExitOffer).
        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowContextTests {

    static func packageComponent(
        _ identifier: String,
        isDefault: Bool = false,
        promoCode: String? = nil,
        children: [PaywallComponent] = []
    ) -> PaywallComponent {
        return .package(.init(
            packageID: identifier,
            isSelectedByDefault: isDefault,
            applePromoOfferProductCode: promoCode,
            stack: .init(components: children)
        ))
    }

    static func sheetButton(_ components: [PaywallComponent]) -> PaywallComponent {
        return .button(.init(
            action: .navigateTo(destination: .sheet(sheet: .init(
                id: "all_plans", name: nil, stack: .init(components: components), backgroundBlur: false, size: nil
            ))),
            stack: .init(components: [])
        ))
    }

    static func makeSheetContext(
        footer: [PaywallComponent]? = nil,
        header: PaywallComponent.HeaderComponent? = nil
    ) throws -> WorkflowContext {
        let products: [(PackageType, Decimal, SubscriptionPeriod)] = [
            (.annual, 79.99, .init(value: 1, unit: .year)),
            (.threeMonth, 34.99, .init(value: 3, unit: .month)),
            (.monthly, 14.99, .init(value: 1, unit: .month))
        ]
        let packages = products.map { type, price, period in
            Package(
                identifier: type.identifier,
                packageType: type,
                storeProduct: TestStoreProduct(
                    localizedTitle: type.identifier, price: price, currencyCode: "USD",
                    localizedPriceString: "$\(price)", productIdentifier: type.identifier,
                    productType: .autoRenewableSubscription, localizedDescription: "",
                    subscriptionPeriod: period, locale: Locale(identifier: "en_US")
                ).toStoreProduct(),
                offeringIdentifier: "offering_test", webCheckoutUrl: nil
            )
        }
        let offering = Offering(
            identifier: "offering_test", serverDescription: "Test", metadata: [:],
            paywall: nil, availablePackages: packages, webCheckoutUrl: nil
        )
        let screen = WorkflowScreen(
            name: nil, templateName: "test", assetBaseURL: try XCTUnwrap(URL(string: "https://example.com")),
            componentsConfig: .init(base: .init(
                stack: .init(components: []),
                header: header,
                stickyFooter: .init(stack: .init(components: footer ?? [
                    Self.packageComponent("$rc_annual", isDefault: true),
                    Self.sheetButton([
                        Self.packageComponent("$rc_annual"),
                        Self.packageComponent("$rc_three_month"),
                        Self.packageComponent("$rc_monthly")
                    ])
                ])),
                background: .color(.init(light: .hex("#FFFFFF")))
            )),
            componentsLocalizations: [:], defaultLocale: "en_US", offeringIdentifier: offering.identifier
        )
        let workflow = PublishedWorkflow(
            id: "wf_test", displayName: "Test", initialStepId: "intro", singleStepFallbackId: "paywall",
            steps: [
                "intro": .init(id: "intro", type: "screen", screenId: nil),
                "paywall": .init(id: "paywall", type: "screen", screenId: "screen")
            ],
            screens: ["screen": screen]
        )
        var uiConfig = UIConfig.empty
        uiConfig.localizations = ["en_US": ["percent": "%d%%"]]
        return WorkflowContext(
            workflow: workflow, uiConfig: uiConfig, allOfferings: Self.makeOfferings(offering),
            initialOffering: offering, presentedOfferingContext: nil
        )
    }

    @MainActor
    static func discountText(context: PackageContext) throws -> String {
        var uiConfig = UIConfig.empty
        uiConfig.localizations = ["en_US": ["percent": "%d%%"]]
        let viewModel = try TextComponentViewModel(
            localizationProvider: .init(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["discount": .string("{{ product.relative_discount }}")]
            ),
            uiConfigProvider: .init(uiConfig: uiConfig),
            component: .init(text: "discount", color: .init(light: .hex("#000000")))
        )
        var result: String?
        _ = viewModel.styles(
            state: .default, condition: .compact, selectedPackageId: context.package?.identifier,
            packageContext: context, isEligibleForIntroOffer: false, promoOffer: nil
        ) { style -> EmptyView in
            result = style.text
            return EmptyView()
        }
        return try XCTUnwrap(result)
    }

    static func makeOfferings(_ offering: Offering) -> Offerings {
        return self.makeOfferings([offering])
    }

    static func makeOfferings(_ offerings: [Offering]) -> Offerings {
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

    static func makeOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: TestData.paywallWithIntroOffer,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

    static func makePresentedOfferingContext() -> PresentedOfferingContext {
        return .init(
            offeringIdentifier: "offering_a",
            placementIdentifier: "home_screen",
            targetingContext: .init(revision: 7, ruleId: "rule_1")
        )
    }

    typealias PackageSpec = (id: String, isDefault: Bool)

    /// Builds a `WorkflowContext` with two package-bearing steps:
    /// - `step_fallback` (set as `singleStepFallbackId`) with `fallbackPackages`
    /// - `step_own` with `ownStepPackages` (may be empty to simulate a packageless step)
    static func makeWorkflowContextWithFallbackAndOwnStep(
        fallbackPackages: [PackageSpec],
        ownStepPackages: [PackageSpec]
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let allPackages = (fallbackPackages + ownStepPackages)
            .map { spec in
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
            availablePackages: allPackages,
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

        func screenJSON(packages: [PackageSpec]) -> String {
            let componentsJSON = packages.map { pkg in
                """
                {
                    "type": "package",
                    "packageId": "\(pkg.id)",
                    "isSelectedByDefault": \(pkg.isDefault),
                    "stack": \(Self.minimalStackJSON())
                }
                """
            }.joined(separator: ",")
            return """
            {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "offering_identifier": "\(offeringId)",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": \(Self.minimalStackJSON(components: "[\(componentsJSON)]")),
                  "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
                }
              }
            }
            """
        }

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          "single_step_fallback_id": "step_fallback",
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen" },
            "step_fallback": { "id": "step_fallback", "type": "screen", "screen_id": "screen_fallback" },
            "step_own": { "id": "step_own", "type": "screen", "screen_id": "screen_own" }
          },
          "screens": {
            "screen_fallback": \(screenJSON(packages: fallbackPackages)),
            "screen_own": \(screenJSON(packages: ownStepPackages))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        return WorkflowContext(
            workflow: workflow,
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

    static func makeWorkflowContextWithPackageStep(
        stepId: String,
        packages: [PackageSpec],
        singleStepFallbackId: String? = nil
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let fallbackJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""
        let componentsJSON = packages
            .map { pkg in
                """
                {
                    "type": "package",
                    "packageId": "\(pkg.id)",
                    "isSelectedByDefault": \(pkg.isDefault),
                    "stack": \(Self.minimalStackJSON())
                }
                """
            }
            .joined(separator: ",")

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          \(fallbackJSON)
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen" },
            "\(stepId)": { "id": "\(stepId)", "type": "screen", "screen_id": "screen_target" }
          },
          "screens": {
            "screen_target": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "offering_identifier": "\(offeringId)",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": \(Self.minimalStackJSON(components: "[\(componentsJSON)]")),
                  "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
                }
              }
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )

        let rcPackages = packages.map { spec in
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
            availablePackages: rcPackages,
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

    /// Builds a `WorkflowContext` where `step_fallback` and `step_own` each resolve to a
    /// *distinct* offering. Use this helper to verify that carry-forward logic selects the
    /// Package object that belongs to the **destination** step's offering, not the source's.
    static func makeWorkflowContextWithMultiOfferingSteps(
        fallbackOfferingId: String,
        fallbackPackages: [PackageSpec],
        ownOfferingId: String,
        ownPackages: [PackageSpec]
    ) throws -> WorkflowContext {
        func rcPackages(_ specs: [PackageSpec], offeringId: String) -> [Package] {
            specs.map { spec in
                Package(
                    identifier: spec.id,
                    packageType: .custom,
                    storeProduct: TestData.monthlyPackage.storeProduct,
                    offeringIdentifier: offeringId,
                    webCheckoutUrl: nil
                )
            }
        }

        let fallbackOffering = Offering(
            identifier: fallbackOfferingId,
            serverDescription: "Fallback",
            metadata: [:],
            paywall: nil,
            availablePackages: rcPackages(fallbackPackages, offeringId: fallbackOfferingId),
            webCheckoutUrl: nil
        )
        let ownOffering = Offering(
            identifier: ownOfferingId,
            serverDescription: "Own",
            metadata: [:],
            paywall: nil,
            availablePackages: rcPackages(ownPackages, offeringId: ownOfferingId),
            webCheckoutUrl: nil
        )
        let offerings = Offerings(
            offerings: [fallbackOfferingId: fallbackOffering, ownOfferingId: ownOffering],
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

        func screenJSON(packages: [PackageSpec], offeringId: String) -> String {
            let componentsJSON = packages.map { pkg in
                """
                {
                    "type": "package",
                    "packageId": "\(pkg.id)",
                    "isSelectedByDefault": \(pkg.isDefault),
                    "stack": \(Self.minimalStackJSON())
                }
                """
            }.joined(separator: ",")
            return """
            {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "offering_identifier": "\(offeringId)",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": \(Self.minimalStackJSON(components: "[\(componentsJSON)]")),
                  "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
                }
              }
            }
            """
        }

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          "single_step_fallback_id": "step_fallback",
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen" },
            "step_fallback": { "id": "step_fallback", "type": "screen", "screen_id": "screen_fallback" },
            "step_own": { "id": "step_own", "type": "screen", "screen_id": "screen_own" }
          },
          "screens": {
            "screen_fallback": \(screenJSON(packages: fallbackPackages, offeringId: fallbackOfferingId)),
            "screen_own": \(screenJSON(packages: ownPackages, offeringId: ownOfferingId))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        return WorkflowContext(
            workflow: workflow,
            allOfferings: offerings,
            initialOffering: fallbackOffering,
            presentedOfferingContext: nil
        )
    }

    static func minimalStackJSON(components: String = "[]") -> String {
        return """
        {
          "type": "stack", "components": \(components),
          "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
          "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
          "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
          "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
        }
        """
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

    static func makeWorkflowWithSingleStepFallback(singleStepFallbackId: String) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "single_step_fallback_id": "\(singleStepFallbackId)",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON())
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

    static func makeWorkflowWithExitOffer(
        singleStepFallbackId: String,
        exitOfferOfferingId: String
    ) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "single_step_fallback_id": "\(singleStepFallbackId)",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON(exitOfferOfferingId: exitOfferOfferingId))
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

    static func makeMultiPageWorkflowWithExitOffer(
        exitOfferOfferingId: String,
        onStepId: String
    ) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" },
            "\(onStepId)": { "id": "\(onStepId)", "type": "screen", "screen_id": "screen_2" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON()),
            "screen_2": \(Self.screenJSON(exitOfferOfferingId: exitOfferOfferingId))
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

    static func screenJSON(exitOfferOfferingId: String? = nil) -> String {
        let exitOffersJSON = exitOfferOfferingId.map {
            #", "exit_offers": { "dismiss": { "offering_id": "\#($0)" } }"#
        } ?? ""
        return """
        {
          "template_name": "tmpl",
          "asset_base_url": "https://assets.revenuecat.com",
          "default_locale": "en_US",
          "components_localizations": {},
          "components_config": {
            "base": {
              "stack": {
                "type": "stack", "components": [],
                "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
              },
              "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
            }
          }\(exitOffersJSON)
        }
        """
    }

}

#endif

#if !os(tvOS) // For Paywalls V2
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowContext {

    init(
        workflow: PublishedWorkflow,
        allOfferings: Offerings,
        initialOffering: Offering,
        presentedOfferingContext: PresentedOfferingContext?
    ) {
        self.init(
            workflow: workflow,
            uiConfig: .empty,
            allOfferings: allOfferings,
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )
    }

}

#endif
