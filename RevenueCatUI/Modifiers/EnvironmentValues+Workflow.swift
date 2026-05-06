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
    /// This crossfades outgoing and incoming header buttons during page transitions.
    let headerButtonOpacity: CGFloat

    static let identity = Self(pageOffset: 0, headerButtonOpacity: 1)

}

/// Package-related state injected by `WorkflowPaywallView` into each `PaywallsV2View` page.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPackageContext {

    /// Package selected on the previous workflow step, forwarded to the current step as its
    /// initial selection (forward-only — back navigation does not set this).
    var contextPackage: Package?

    /// Default package from the workflow's `singleStepFallbackId` step, used by packageless
    /// screens to resolve price/period template variables.
    var fallbackPackage: Package?

    /// Called when the user's selected package changes inside a workflow paywall step.
    var onPackageSelected: ((Package?) -> Void)?

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowTriggerActionKey: EnvironmentKey {
    static let defaultValue: ((String) -> Bool)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowPageTransitionContextKey: EnvironmentKey {
    static let defaultValue = WorkflowPageTransitionContext.identity
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct IsWorkflowHeaderKey: EnvironmentKey {
    /// Marks the header subtree so only header buttons consume workflow page transition context.
    static let defaultValue = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowPackageContextKey: EnvironmentKey {
    static let defaultValue = WorkflowPackageContext()
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

    var workflowPageTransitionContext: WorkflowPageTransitionContext {
        get { self[WorkflowPageTransitionContextKey.self] }
        set { self[WorkflowPageTransitionContextKey.self] = newValue }
    }

    var isWorkflowHeader: Bool {
        get { self[IsWorkflowHeaderKey.self] }
        set { self[IsWorkflowHeaderKey.self] = newValue }
    }

    var workflowPackageContext: WorkflowPackageContext {
        get { self[WorkflowPackageContextKey.self] }
        set { self[WorkflowPackageContextKey.self] = newValue }
    }
}

#endif
