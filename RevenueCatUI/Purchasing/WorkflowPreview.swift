//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPreview.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Injection seam for previewing workflows from data supplied by a companion app (e.g. dashboard
/// drafts), without going through the SDK's `/workflows` fetch. Build a ``WorkflowContext`` here and
/// pass it to `PaywallView(workflowContext:)`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public enum WorkflowPreview {

    /// Builds a render-ready ``WorkflowContext`` from injected data, with no backend fetch.
    ///
    /// - Parameters:
    ///   - workflow: The workflow to render, assembled from dashboard data.
    ///   - offerings: One offering per `offeringIdentifier` referenced by the workflow's screens.
    ///     They carry PACKAGES/PRICING ONLY: per-screen paywall components come from
    ///     `workflow.screens` and override each offering's components, so the supplied offerings
    ///     must NOT carry paywall components.
    ///   - presentedOfferingContext: Optional placement/targeting metadata to propagate.
    /// - Throws: `PaywallError.offeringNotFound` when the workflow has no initial screen, or a
    ///   screen references an offering id absent from `offerings`.
    @_spi(Internal) public static func makeContext(
        workflow: PublishedWorkflow,
        offerings: [Offering],
        presentedOfferingContext: PresentedOfferingContext? = nil
    ) throws -> WorkflowContext {
        let allOfferings = Offerings.preview(offerings: offerings)
        return try PurchaseHandler.makeWorkflowContext(
            workflow: workflow,
            allOfferings: allOfferings,
            presentedOfferingContext: presentedOfferingContext,
            triggerOfferingIdentifier: workflow.id
        )
    }

}

#endif
