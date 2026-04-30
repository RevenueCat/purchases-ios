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

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPageTransitionContext {

    let pageOffset: CGFloat
    let headerButtonOpacity: CGFloat

    static let identity = Self(pageOffset: 0, headerButtonOpacity: 1)

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
    static let defaultValue = false
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
}

#endif
