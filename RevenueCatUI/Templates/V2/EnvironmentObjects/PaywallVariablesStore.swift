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

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Paywall-instance-scoped mutable variables store.
///
/// Holds variable values mutated by interactive components during a single paywall presentation.
/// Exposed to descendant components via `EnvironmentValues.paywallVariablesStore` so any view model
/// can fold its values into a `ConditionContext` and any interactive view can dispatch updates.
///
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class PaywallVariablesStore: ObservableObject {

    /// The current variable-value mutations. Changes trigger SwiftUI invalidation of subscribers.
    @Published public private(set) var values: [String: PaywallComponent.ConditionValue]

    public init(initialValues: [String: PaywallComponent.ConditionValue] = [:]) {
        self.values = initialValues
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
            switch value {
            case .literal(let literal):
                values[key] = literal
            case .payloadReference:
                if let payload {
                    values[key] = payload
                }
                // No payload available, skip silently. Defensive: the JSON should only
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

    /// Default empty store. Components only read or write through this default when the paywall
    /// root has not injected a per-instance store — in practice paywalls without any `variableUpdates`
    /// declarations never touch the store.
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
