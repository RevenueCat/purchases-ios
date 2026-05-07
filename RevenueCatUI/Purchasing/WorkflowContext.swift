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

    /// Resolves the default package from the workflow's `singleStepFallbackId` step so that
    /// packageless early screens can still resolve price/period template variables.
    var defaultPackage: Package? {
        guard let fallbackStepId = self.workflow.singleStepFallbackId else {
            return nil
        }

        guard let step = self.workflow.steps[fallbackStepId],
              let screenId = step.screenId,
              let screen = self.workflow.screens[screenId],
              let offering = self.offering(for: screen.offeringIdentifier) else {
            Logger.warning(Strings.workflow_fallback_package_unresolvable(stepId: fallbackStepId))
            return nil
        }

        let base = screen.componentsConfig.base
        let allComponents = base.stack.components
            + (base.stickyFooter?.stack.components ?? [])
        let visible = Self.collectVisiblePackages(in: allComponents, offering: offering)

        return visible.first(where: { $0.isSelectedByDefault })?.package
            ?? visible.first?.package
    }

    private static func collectVisiblePackages(
        in components: [PaywallComponent],
        offering: Offering
    ) -> [(package: Package, isSelectedByDefault: Bool)] {
        return components.reduce(into: []) { result, component in
            switch component {
            case .package(let pkg) where pkg.visible ?? true:
                if let rcPackage = offering.package(identifier: pkg.packageID) {
                    result.append((package: rcPackage, isSelectedByDefault: pkg.isSelectedByDefault))
                }
            case .stack(let stack):
                result += Self.collectVisiblePackages(in: stack.components, offering: offering)
            case .tabs(let tabs):
                result += Self.collectVisiblePackages(
                    in: tabs.tabs.flatMap { $0.stack.components }, offering: offering)
            default:
                break
            }
        }
    }
}

#endif
