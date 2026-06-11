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

/// Used to preview workflows from the RC mobile app, without going through the SDK's `/workflows`
/// fetch. Build a ``WorkflowContext`` here and pass it to `PaywallView(workflowContext:)`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public enum WorkflowPreview {

    /// Builds a render-ready ``WorkflowContext`` from injected data, with no backend fetch.
    /// `offerings` carry packages/pricing only (one per offering id the workflow references); the
    /// paywall components come from `workflow.screens`, so the offerings must not carry components.
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
