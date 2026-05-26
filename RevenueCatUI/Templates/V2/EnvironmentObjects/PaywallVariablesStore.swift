//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallVariablesStore.swift
//
//  Created for paywall state management.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Paywall-instance-scoped mutable variables store.
///
/// Seeded from the paywall's variable defaults when it opens, mutated by component-declared
/// `variableUpdates`, and discarded when the paywall closes. Exposed to descendant components
/// via `EnvironmentValues.paywallVariablesStore` so any view model can fold its values into a
/// `ConditionContext` and any interactive view can dispatch updates.
///
/// `mutableKeys` lists the variable names that components are allowed to write to. Variables
/// not in this set are read-only at runtime; `apply(...)` calls referencing them no-op.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class PaywallVariablesStore: ObservableObject {

    /// The current variable-value dictionary. Changes trigger SwiftUI invalidation of subscribers.
    @Published public private(set) var values: [String: PaywallComponent.ConditionValue]

    /// Set of variable names that are mutable from component interactions. Variables not in this
    /// set are treated as read-only — `apply(...)` will skip writes targeting them.
    private let mutableKeys: Set<String>

    public init(
        initialValues: [String: PaywallComponent.ConditionValue] = [:],
        mutableKeys: Set<String> = []
    ) {
        self.values = initialValues
        self.mutableKeys = mutableKeys
    }

    /// Applies a batch of declarative variable updates declared on an interactive component.
    /// - Parameters:
    ///   - updates: The updates parsed from the component's JSON `variableUpdates` field.
    ///   - payload: The interaction's payload value, substituted for `"$value"` references.
    ///              Pass `nil` for interactions without a payload (e.g. button taps).
    ///
    /// Mutation is dispatched to the main actor so SwiftUI observers update on the main thread.
    public func apply(
        _ updates: [PaywallComponent.VariableUpdate],
        payload: PaywallComponent.ConditionValue? = nil
    ) {
        guard !updates.isEmpty else { return }
        if Thread.isMainThread {
            self.applyOnMain(updates, payload: payload)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.applyOnMain(updates, payload: payload)
            }
        }
    }

    private func applyOnMain(
        _ updates: [PaywallComponent.VariableUpdate],
        payload: PaywallComponent.ConditionValue?
    ) {
        var next = self.values
        for update in updates {
            apply(update, payload: payload, into: &next)
        }
        if next != self.values {
            self.values = next
        }
    }

    private func apply(
        _ update: PaywallComponent.VariableUpdate,
        payload: PaywallComponent.ConditionValue?,
        into values: inout [String: PaywallComponent.ConditionValue]
    ) {
        switch update {
        case .set(let key, let value):
            // Gate writes on mutability. Empty mutableKeys means "no gating", used as a back-compat
            // shim during the migration from the legacy state field. Once dashboard-driven
            // mutability flags ship, the set will be non-empty whenever any variable is mutable.
            if !self.mutableKeys.isEmpty, !self.mutableKeys.contains(key) {
                return
            }
            switch value {
            case .literal(let literal):
                values[key] = literal
            case .payloadReference:
                if let payload {
                    values[key] = payload
                }
                // No payload available — skip silently. Defensive: the JSON should only
                // reference "$value" on components whose interaction provides one.
            }
        case .unsupported:
            break
        }
    }

}

// MARK: - Environment integration

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallVariablesStoreKey: EnvironmentKey {

    /// Default shared empty store. Components only read or write through this default when the
    /// paywall root has not injected a per-instance store. In practice that means paywalls without
    /// any mutable variables — those components never touch the store.
    static let defaultValue: PaywallVariablesStore = PaywallVariablesStore()

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallVariablesStore: PaywallVariablesStore {
        get { self[PaywallVariablesStoreKey.self] }
        set { self[PaywallVariablesStoreKey.self] = newValue }
    }

}

#endif
