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
    var fallbackPackage: Package? {
        guard let fallbackStepId = self.workflow.singleStepFallbackId,
              let step = self.workflow.steps[fallbackStepId],
              let screenId = step.screenId,
              let screen = self.workflow.screens[screenId],
              let offering = self.offering(for: screen.offeringIdentifier) else {
            return nil
        }

        let visible = Self.collectVisiblePackages(
            in: screen.componentsConfig.base.stack.components,
            offering: offering
        )

        return visible.first(where: { $0.isSelectedByDefault })?.package
            ?? visible.first?.package
    }

    private static func collectVisiblePackages(
        in components: [PaywallComponent],
        offering: Offering
    ) -> [(package: Package, isSelectedByDefault: Bool)] {
        return components.reduce(into: []) { result, component in
            switch component {
            case .package(let pkg) where pkg.visible != false:
                if let rcPackage = offering.package(identifier: pkg.packageID) {
                    result.append((package: rcPackage, isSelectedByDefault: pkg.isSelectedByDefault))
                }
            case .stack(let stack):
                result += Self.collectVisiblePackages(in: stack.components, offering: offering)
            default:
                break
            }
        }
    }
}

#endif
