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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowTriggerActionKey: EnvironmentKey {
    static let defaultValue: ((String) -> Bool)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CloseWorkflowActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
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
private struct WorkflowFallbackContextKey: EnvironmentKey {
    // Workflow-wide static context derived from `singleStepFallbackId`.
    // Carries both a selectedPackage AND the full packages array so that packageless
    // screens (which have no offerings of their own) can still populate variableContext
    // and resolve price/period template variables.
    // Same value on every page for the lifetime of the workflow.
    static let defaultValue: WorkflowPackageContext? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowCarriedPackageKey: EnvironmentKey {
    // Per-step carry-forward: the single Package the user selected (or that was resolved
    // as the default) on the previous step. Changes on every forward navigation; nil on
    // back navigation. Only a Package — no packages array — because its sole job is
    // pre-selection, not variable resolution.
    static let defaultValue: Package? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowOnPackageSelectedKey: EnvironmentKey {
    static let defaultValue: ((Package) -> Void)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowOnInitialPackageResolvedKey: EnvironmentKey {
    static let defaultValue: ((Package) -> Void)? = nil
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

    /// Workflow-wide static fallback context derived from `singleStepFallbackId`.
    ///
    /// Carries `selectedPackage` + the full `packages` array so packageless screens can
    /// populate their `variableContext` and resolve price/period template variables even
    /// when the step has no offering of its own. The same value is set on every page for
    /// the lifetime of the workflow.
    ///
    /// Distinct from `workflowCarriedPackage`: this is a stable, workflow-scoped fallback;
    /// the carried package is a per-step value that changes with each navigation.
    var workflowFallbackContext: WorkflowPackageContext? {
        get { self[WorkflowFallbackContextKey.self] }
        set { self[WorkflowFallbackContextKey.self] = newValue }
    }

    /// Per-step carry-forward: the package the user selected (or that was resolved as the
    /// default) on the immediately preceding workflow step.
    ///
    /// Set fresh on each forward navigation; cleared on back navigation. Components that
    /// create their own `PackageContext` (e.g. tabs) read this to pre-select a matching
    /// package, validated against their own offering's package list.
    ///
    /// Distinct from `workflowFallbackContext`: this changes on every navigation and carries
    /// only a single `Package` — no packages array — because its sole job is pre-selection,
    /// not variable resolution.
    var workflowCarriedPackage: Package? {
        get { self[WorkflowCarriedPackageKey.self] }
        set { self[WorkflowCarriedPackageKey.self] = newValue }
    }

    /// Called by `PaywallsV2View` when the user selects a package, so `WorkflowPaywallView`
    /// can carry it forward to the next step.
    var workflowOnPackageSelected: ((Package) -> Void)? {
        get { self[WorkflowOnPackageSelectedKey.self] }
        set { self[WorkflowOnPackageSelectedKey.self] = newValue }
    }

    /// Called by `PaywallsV2View` when a forward-rendered workflow step resolves its
    /// initial package so `WorkflowPaywallView` can carry it into the next step even
    /// if the user proceeds without explicitly re-selecting.
    var workflowOnInitialPackageResolved: ((Package) -> Void)? {
        get { self[WorkflowOnInitialPackageResolvedKey.self] }
        set { self[WorkflowOnInitialPackageResolvedKey.self] = newValue }
    }

    /// Dismisses the entire paywall, bypassing any intermediate workflow step or sheet.
    /// Set at the outermost paywall view so it remains accessible from nested contexts (e.g. sheets)
    /// where the local `onDismiss` only closes the sheet.
    var closeWorkflowAction: (() -> Void)? {
        get { self[CloseWorkflowActionKey.self] }
        set { self[CloseWorkflowActionKey.self] = newValue }
    }
}

#endif
