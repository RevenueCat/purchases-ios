//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowContext.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Render-ready input for a workflow paywall. Built internally (from a backend fetch, a warm cache,
/// or `WorkflowPreview.makeContext` for injected data) and passed into ``PaywallView``; it has no
/// public initializer because callers never assemble it directly.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct WorkflowContext {
    let workflow: PublishedWorkflow
    let allOfferings: Offerings
    let initialOffering: Offering
    /// Preserved so every subsequent step's offering can carry the same placement/targeting metadata.
    let presentedOfferingContext: PresentedOfferingContext?
    /// Package context from `singleStepFallbackId`, precomputed because it is stable for a workflow.
    let workflowPackageContext: WorkflowPackageContext?

    init(
        workflow: PublishedWorkflow,
        allOfferings: Offerings,
        initialOffering: Offering,
        presentedOfferingContext: PresentedOfferingContext?
    ) {
        self.workflow = workflow
        self.allOfferings = allOfferings
        self.initialOffering = initialOffering
        self.presentedOfferingContext = presentedOfferingContext

        let workflowPackageContext = Self.workflowPackageContext(
            workflow: workflow,
            allOfferings: allOfferings,
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )
        if let singleWorkflowStepFallbackId = workflow.singleStepFallbackId, workflowPackageContext == nil {
            Logger.warning(Strings.workflow_package_context_unresolvable(stepId: singleWorkflowStepFallbackId))
        }
        self.workflowPackageContext = workflowPackageContext
    }

    func offering(for offeringIdentifier: String?) -> Offering? {
        return Self.offering(
            for: offeringIdentifier,
            allOfferings: self.allOfferings,
            initialOffering: self.initialOffering,
            presentedOfferingContext: self.presentedOfferingContext
        )
    }

    /// The step ID from which the exit offer may be triggered.
    /// Used to guard against showing the exit offer when dismissing from a different step.
    var exitOfferTriggeringStepId: String? { exitOfferEntry?.triggeringStepId }

    /// The exit offer resolved synchronously from `allOfferings`.
    /// Non-nil only when an exit offer is configured and its offering is present in the loaded offerings bundle.
    var exitOfferOffering: Offering? {
        guard let entry = exitOfferEntry else { return nil }
        return ExitOfferHelper.validExitOffer(
            offeringId: entry.offeringId,
            currentOfferingId: initialOffering.identifier,
            from: allOfferings
        )
    }

    /// Returns a `WorkflowExitOfferContext` if `stepId` is the exit-offer triggering step
    /// and the exit offer offering is present in the loaded offerings bundle.
    /// Evaluates `exitOfferEntry` once, avoiding the double traversal that would occur
    /// when reading `exitOfferTriggeringStepId` and `exitOfferOffering` separately.
    func exitOfferContext(forStepId stepId: String) -> WorkflowExitOfferContext? {
        guard let entry = exitOfferEntry,
              stepId == entry.triggeringStepId,
              let offering = ExitOfferHelper.validExitOffer(
                  offeringId: entry.offeringId,
                  currentOfferingId: initialOffering.identifier,
                  from: allOfferings
              ) else { return nil }
        return WorkflowExitOfferContext(exitOfferOffering: offering)
    }

    /// Resolves the exit offer entry from `singleStepFallbackId`'s screen.
    /// Returns `nil` if `singleStepFallbackId` is absent or its screen has no exit offer configured.
    /// Mirrors Android's `dismissExitOffer` which also relies solely on `singleStepFallbackId`.
    private var exitOfferEntry: (offeringId: String, triggeringStepId: String)? {
        guard let stepId = workflow.singleStepFallbackId,
              let step = workflow.steps[stepId],
              let screenId = step.screenId,
              let screen = workflow.screens[screenId],
              let offeringId = screen.exitOffers?.dismiss?.offeringId else {
            return nil
        }
        return (offeringId: offeringId, triggeringStepId: stepId)
    }

    /// Returns the effective package context for `stepId`, preferring `preferredPackage` as the
    /// selection when that package is present in the step's available packages.
    ///
    /// Used for forward navigation carry-forward: when the user selected a package on a prior step,
    /// that selection should seed the next step when the package is available there.
    /// Falls back to the workflow-global default (`workflowPackageContext`) if `preferredPackage`
    /// is absent from the step. As a last resort (workflow has no `singleStepFallbackId`), returns
    /// the step's own authored default from `isSelectedByDefault`.
    func effectivePackageContext(for stepId: String, preferring preferredPackage: Package?) -> WorkflowPackageContext? {
        let wfContext = self.workflowPackageContext
        guard let base = self.packageContext(for: stepId) ?? wfContext else {
            return nil
        }

        guard let preferredPackage else {
            return base
        }

        if let matched = base.packages.first(where: { $0.identifier == preferredPackage.identifier }) {
            return .init(selectedPackage: matched,
                         packages: base.packages,
                         promoOfferCodesByPackageId: base.promoOfferCodesByPackageId)
        }

        if let wfDefault = wfContext?.selectedPackage,
           let matched = base.packages.first(where: { $0.identifier == wfDefault.identifier }) {
            return .init(selectedPackage: matched,
                         packages: base.packages,
                         promoOfferCodesByPackageId: base.promoOfferCodesByPackageId)
        }

        return base
    }

    /// Resolves the package context for any step by scanning its screen's components.
    /// Returns `nil` if the step, screen, or offering cannot be resolved, or if the step has no package components.
    func packageContext(for stepId: String) -> WorkflowPackageContext? {
        guard let step = self.workflow.steps[stepId],
              let screenId = step.screenId,
              let screen = self.workflow.screens[screenId],
              let offering = self.offering(for: screen.offeringIdentifier) else {
            return nil
        }

        return self.workflowPackageContext(for: screen, offering: offering)
    }

    private func workflowPackageContext(
        for screen: WorkflowScreen,
        offering: Offering
    ) -> WorkflowPackageContext? {
        let base = screen.componentsConfig.base
        return Self.workflowPackageContext(for: base, offering: offering)
    }

    private static func workflowPackageContext(
        workflow: PublishedWorkflow,
        allOfferings: Offerings,
        initialOffering: Offering,
        presentedOfferingContext: PresentedOfferingContext?
    ) -> WorkflowPackageContext? {
        guard let singleWorkflowStepFallbackId = workflow.singleStepFallbackId,
              let step = workflow.steps[singleWorkflowStepFallbackId],
              let screenId = step.screenId,
              let screen = workflow.screens[screenId],
              let offering = Self.offering(
                  for: screen.offeringIdentifier,
                  allOfferings: allOfferings,
                  initialOffering: initialOffering,
                  presentedOfferingContext: presentedOfferingContext
              ) else {
            return nil
        }

        return Self.workflowPackageContext(for: screen.componentsConfig.base, offering: offering)
    }

    private static func workflowPackageContext(
        for base: PaywallComponentsData.PaywallComponentsConfig,
        offering: Offering
    ) -> WorkflowPackageContext? {
        let allComponents = base.stack.components
            + (base.stickyFooter?.stack.components ?? [])
        let packages = Self.collectPackages(in: allComponents, offering: offering)

        guard let selectedPackage = packages.first(where: { $0.isSelectedByDefault })?.package
                ?? packages.first?.package else {
            return nil
        }

        let promoOfferCodes = packages.reduce(into: [String: String]()) { result, entry in
            if let code = entry.promoOfferCode {
                result[entry.package.identifier] = code
            }
        }

        return .init(
            selectedPackage: selectedPackage,
            packages: packages.map(\.package),
            promoOfferCodesByPackageId: promoOfferCodes
        )
    }

    private static func offering(
        for offeringIdentifier: String?,
        allOfferings: Offerings,
        initialOffering: Offering,
        presentedOfferingContext: PresentedOfferingContext?
    ) -> Offering? {
        guard let offeringIdentifier else {
            return initialOffering
        }

        if initialOffering.identifier == offeringIdentifier {
            return initialOffering
        }

        guard let offering = allOfferings.all[offeringIdentifier] else {
            return nil
        }

        guard let presentedOfferingContext else {
            return offering
        }

        return offering.withPresentedOfferingContext(presentedOfferingContext)
    }

    private static func collectPackages(
        in components: [PaywallComponent],
        offering: Offering
    ) -> [(package: Package, isSelectedByDefault: Bool, promoOfferCode: String?)] {
        return components.reduce(into: []) { result, component in
            switch component {
            case .package(let pkg):
                if let rcPackage = offering.package(identifier: pkg.packageID) {
                    result.append((package: rcPackage,
                                   isSelectedByDefault: pkg.isSelectedByDefault,
                                   promoOfferCode: pkg.applePromoOfferProductCode))
                }
            case .stack(let stack):
                result += Self.collectPackages(in: stack.components, offering: offering)
            case .tabs(let tabs):
                result += Self.collectPackages(
                    in: tabs.tabs.flatMap { $0.stack.components }, offering: offering)
            case .carousel(let carousel):
                result += Self.collectPackages(
                    in: carousel.pages.flatMap { $0.components }, offering: offering)
            default:
                break
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPackageContext {
    let selectedPackage: Package
    let packages: [Package]
    /// Apple promo offer product code per package identifier, used to resolve `promo_offer_condition`
    /// on a workflow step that inherits this package set but hosts no package component of its own.
    let promoOfferCodesByPackageId: [String: String]

    init(
        selectedPackage: Package,
        packages: [Package],
        promoOfferCodesByPackageId: [String: String] = [:]
    ) {
        self.selectedPackage = selectedPackage
        self.packages = packages
        self.promoOfferCodesByPackageId = promoOfferCodesByPackageId
    }
}

// Temporary launch-argument gate — remove once workflows are fully released.
extension ProcessInfo {

    var workflowsEndpointEnabled: Bool {
        arguments.contains("-EnableWorkflowsEndpoint")
    }

}

#endif
