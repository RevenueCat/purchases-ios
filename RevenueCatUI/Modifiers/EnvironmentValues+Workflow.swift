//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EnvironmentValues+Workflow.swift

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPageTransitionContext {

    /// Current horizontal offset applied to the page by `WorkflowPaywallView`.
    /// Header buttons use the inverse value so they stay visually fixed while page content slides.
    let pageOffset: CGFloat
    /// Opacity for buttons rendered inside workflow headers.
    /// Header buttons fade when a header enters or leaves, but stay stable when both pages share the same header.
    let headerButtonOpacity: CGFloat
    /// Whether the page is currently participating in a workflow-level transition.
    /// Child component entrance transitions and horizontal safe-area bleed should be suppressed while this is true.
    let isTransitioning: Bool

    static let identity = Self(pageOffset: 0, headerButtonOpacity: 1, isTransitioning: false)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowRenderingContext {

    /// Transition state consumed by workflow page bodies and header controls.
    let pageTransition: WorkflowPageTransitionContext
    /// Whether page-owned headers should be hidden while a workflow-level header overlay is visible.
    /// The header layout is preserved so body content does not jump when the overlay appears.
    let pageHeaderSuppressed: Bool
    /// Marks the header subtree so only header buttons consume workflow page transition context.
    let isHeader: Bool

    static let identity = Self()

    init(
        pageTransition: WorkflowPageTransitionContext = .identity,
        pageHeaderSuppressed: Bool = false,
        isHeader: Bool = false
    ) {
        self.pageTransition = pageTransition
        self.pageHeaderSuppressed = pageHeaderSuppressed
        self.isHeader = isHeader
    }

    func markingHeader() -> Self {
        return .init(
            pageTransition: self.pageTransition,
            pageHeaderSuppressed: self.pageHeaderSuppressed,
            isHeader: true
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowTriggerActionKey: EnvironmentKey {
    static let defaultValue: ((String) -> Bool)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CloseWorkflowActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowRenderingContextKey: EnvironmentKey {
    static let defaultValue = WorkflowRenderingContext.identity
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowPackageContextKey: EnvironmentKey {
    /// Package context from the workflow's `singleStepFallbackId` step, used by packageless
    /// screens to resolve price/period template variables.
    static let defaultValue: WorkflowPackageContext? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowExitOfferOfferingBindingKey: EnvironmentKey {
    static let defaultValue: Binding<Offering?> = .constant(nil)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    /// Called when a button with a component `id` is tapped inside a workflow paywall.
    /// Returns `true` if the workflow consumed the trigger (navigator found a matching step),
    /// `false` if not — in which case the button falls through to its normal action.
    var workflowTriggerAction: ((String) -> Bool)? {
        get { self[WorkflowTriggerActionKey.self] }
        set { self[WorkflowTriggerActionKey.self] = newValue }
    }

    var workflowRenderingContext: WorkflowRenderingContext {
        get { self[WorkflowRenderingContextKey.self] }
        set { self[WorkflowRenderingContextKey.self] = newValue }
    }

    var workflowPackageContext: WorkflowPackageContext? {
        get { self[WorkflowPackageContextKey.self] }
        set { self[WorkflowPackageContextKey.self] = newValue }
    }

    /// Dismisses the entire paywall, bypassing any intermediate workflow step or sheet.
    /// Set at the outermost paywall view so it remains accessible from nested contexts (e.g. sheets)
    /// where the local `onDismiss` only closes the sheet.
    var closeWorkflowAction: (() -> Void)? {
        get { self[CloseWorkflowActionKey.self] }
        set { self[CloseWorkflowActionKey.self] = newValue }
    }

    /// A binding injected by `PresentingPaywallModifier` so `WorkflowPaywallView` can write the
    /// resolved exit offer offering directly, bypassing the preference-key path which does not
    /// propagate reliably across the sheet boundary.
    var workflowExitOfferOfferingBinding: Binding<Offering?> {
        get { self[WorkflowExitOfferOfferingBindingKey.self] }
        set { self[WorkflowExitOfferOfferingBindingKey.self] = newValue }
    }
}

#endif
