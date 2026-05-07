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

    /// Resolves the package context from the workflow's `singleStepFallbackId` step so that
    /// packageless early screens can still resolve price/period template variables.
    var workflowPackageContext: WorkflowPackageContext? {
        guard let singleWorkflowStepFallbackId = self.workflow.singleStepFallbackId else {
            return nil
        }

        guard let step = self.workflow.steps[singleWorkflowStepFallbackId],
              let screenId = step.screenId,
              let screen = self.workflow.screens[screenId],
              let offering = self.offering(for: screen.offeringIdentifier) else {
            Logger.warning(Strings.workflow_package_context_unresolvable(stepId: singleWorkflowStepFallbackId))
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

#endif
