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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowContext {
    let workflow: PublishedWorkflow
    let allOfferings: Offerings
    let initialOffering: Offering
    /// Preserved so every subsequent step's offering can carry the same placement/targeting metadata.
    let presentedOfferingContext: PresentedOfferingContext?

    func offering(for offeringIdentifier: String?) -> Offering? {
        guard let offeringIdentifier else {
            return self.initialOffering
        }

        if self.initialOffering.identifier == offeringIdentifier {
            return self.initialOffering
        }

        guard let offering = self.allOfferings.all[offeringIdentifier] else {
            return nil
        }

        guard let presentedOfferingContext else {
            return offering
        }

        return offering.withPresentedOfferingContext(presentedOfferingContext)
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

    /// Resolves the package context from the workflow's `singleStepFallbackId` step so that
    /// packageless early screens can still resolve price/period template variables.
    var workflowPackageContext: WorkflowPackageContext? {
        guard let singleWorkflowStepFallbackId = self.workflow.singleStepFallbackId else {
            return nil
        }

        let context = self.packageContext(for: singleWorkflowStepFallbackId)
        if context == nil {
            Logger.warning(Strings.workflow_package_context_unresolvable(stepId: singleWorkflowStepFallbackId))
        }
        return context
    }

    /// Returns the package context that should be broadcast in the environment for `stepId`.
    /// Prefers the step's own package context when available so that package-bearing steps
    /// use their own configured defaults rather than the global workflow fallback.
    func effectivePackageContext(for stepId: String) -> WorkflowPackageContext? {
        return self.packageContext(for: stepId) ?? self.workflowPackageContext
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

        let base = screen.componentsConfig.base
        let allComponents = base.stack.components
            + (base.stickyFooter?.stack.components ?? [])
        let packages = Self.collectPackages(in: allComponents, offering: offering)

        guard let selectedPackage = packages.first(where: { $0.isSelectedByDefault })?.package
                ?? packages.first?.package else {
            return nil
        }

        return .init(
            selectedPackage: selectedPackage,
            packages: packages.map(\.package)
        )
    }

    private static func collectPackages(
        in components: [PaywallComponent],
        offering: Offering
    ) -> [(package: Package, isSelectedByDefault: Bool)] {
        return components.reduce(into: []) { result, component in
            switch component {
            case .package(let pkg):
                if let rcPackage = offering.package(identifier: pkg.packageID) {
                    result.append((package: rcPackage, isSelectedByDefault: pkg.isSelectedByDefault))
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
}

// Temporary launch-argument gate — remove once workflows are fully released.
extension ProcessInfo {

    var workflowsEndpointEnabled: Bool {
        arguments.contains("-EnableWorkflowsEndpoint")
    }

}

#endif
