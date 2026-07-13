//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallStateStore.swift

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Presentation-session-scoped paywall state store.
///
/// Holds the current values of declared paywall state keys for a single presentation session —
/// the workflow when the paywall is part of one (injected at `WorkflowPaywallView` level so values
/// survive screen navigation), the single paywall otherwise (injected at `PaywallsV2View` level).
/// The store is seeded from the declared defaults and resets when the presentation ends, because
/// its owning view (and therefore the `@StateObject`) is torn down; nothing persists across
/// presentations or app launches.
///
/// Reads feed `ConditionContext` so the override resolver can evaluate `state` conditions;
/// writes come from component `stateUpdates` (wired in later phases).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStore: ObservableObject {

    private let lock = NSLock()
    private var declaredDefaults: [String: PaywallComponent.ConditionValue]
    private var currentValues: [String: PaywallComponent.ConditionValue]
    private var declaredTypes: [String: String]

    /// Creates a store seeded from the given state declarations: each declared key starts out
    /// holding its declared default value.
    init(declarations: [String: PaywallComponent.StateDeclaration] = [:]) {
        let defaults = declarations.mapValues { $0.normalizedDefaultValue }
        self.declaredDefaults = defaults
        self.currentValues = defaults
        self.declaredTypes = declarations.mapValues { $0.type }
    }

    /// The current value of every state key (declared defaults overlaid with any applied updates).
    var values: [String: PaywallComponent.ConditionValue] {
        self.withLock { self.currentValues }
    }

    /// The declared default value of every state key.
    var defaults: [String: PaywallComponent.ConditionValue] {
        self.withLock { self.declaredDefaults }
    }

    /// Registers additional declarations without overwriting keys that are already declared or
    /// hold a value. Lets presentation units whose declarations arrive incrementally (e.g. workflow
    /// screens) contribute their keys to a shared session store.
    func registerDeclarations(_ declarations: [String: PaywallComponent.StateDeclaration]) {
        guard !declarations.isEmpty else { return }

        let changed = self.withLock {
            var didChange = false
            for (key, declaration) in declarations where self.declaredDefaults[key] == nil {
                self.declaredDefaults[key] = declaration.normalizedDefaultValue
                self.declaredTypes[key] = declaration.type
                if self.currentValues[key] == nil {
                    self.currentValues[key] = declaration.normalizedDefaultValue
                    didChange = true
                }
            }
            return didChange
        }

        if changed {
            self.notifyChange()
        }
    }

    /// Applies a batch of declarative state updates declared on an interactive component, in array order.
    /// - Parameters:
    ///   - updates: The updates parsed from the component's JSON `stateUpdates` field.
    ///   - payload: The interaction's payload value, substituted for `"$value"` references.
    ///              Pass `nil` for interactions without a payload (e.g. button taps).
    ///
    /// Writes to undeclared keys and writes whose value type does not match the key's declared
    /// type are ignored — the key keeps its current value, per the component-state spec.
    func apply(
        _ updates: [PaywallComponent.StateUpdate],
        payload: PaywallComponent.ConditionValue? = nil
    ) {
        guard !updates.isEmpty else { return }

        let changed = self.withLock {
            var didChange = false
            for update in updates where self.apply(update, payload: payload) {
                didChange = true
            }
            return didChange
        }

        if changed {
            self.notifyChange()
        }
    }

    /// Resets every key back to its declared default, as when a presentation starts fresh.
    func reset() {
        let changed = self.withLock {
            guard self.currentValues != self.declaredDefaults else { return false }
            self.currentValues = self.declaredDefaults
            return true
        }

        if changed {
            self.notifyChange()
        }
    }

    // MARK: - Private

    /// Applies a single update to `currentValues`. Must be called while holding `lock`.
    /// Returns whether a value changed.
    private func apply(
        _ update: PaywallComponent.StateUpdate,
        payload: PaywallComponent.ConditionValue?
    ) -> Bool {
        switch update {
        case .set(let key, let value):
            let resolvedValue: PaywallComponent.ConditionValue?
            switch value {
            case .literal(let literal):
                resolvedValue = literal
            case .payloadReference:
                // No payload available → skip silently. Defensive: the JSON should only
                // reference "$value" on components whose interaction provides one.
                resolvedValue = payload
            }

            guard let resolvedValue,
                  let newValue = self.normalizedValue(resolvedValue, forKey: key),
                  self.currentValues[key] != newValue else {
                return false
            }

            self.currentValues[key] = newValue
            return true

        case .unsupported:
            return false
        }
    }

    /// Validates a write against the key's declaration. Must be called while holding `lock`.
    /// Returns the value to store (coerced to the declared type where the runtime representation
    /// is ambiguous, e.g. an integral number written to a `double` key), or `nil` when the write
    /// must be ignored (undeclared key or type mismatch).
    private func normalizedValue(
        _ value: PaywallComponent.ConditionValue,
        forKey key: String
    ) -> PaywallComponent.ConditionValue? {
        guard let declaredType = self.declaredTypes[key] else {
            // Undeclared key (e.g. a dangling reference cascade-delete should have cleaned).
            return nil
        }

        typealias ValueType = PaywallComponent.StateDeclaration.ValueType

        switch (declaredType, value) {
        case (ValueType.string, .string),
             (ValueType.boolean, .bool),
             (ValueType.integer, .int),
             (ValueType.double, .double):
            return value
        case (ValueType.double, .int(let intValue)):
            return .double(Double(intValue))
        case (ValueType.integer, .double(let doubleValue)):
            guard let intValue = Int(exactly: doubleValue) else { return nil }
            return .int(intValue)
        default:
            return nil
        }
    }

    private func withLock<T>(_ work: () -> T) -> T {
        self.lock.lock()
        defer { self.lock.unlock() }
        return work()
    }

    /// Notifies SwiftUI observers on the main thread.
    private func notifyChange() {
        if Thread.isMainThread {
            self.objectWillChange.send()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }

}

// MARK: - Environment integration

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateStoreKey: EnvironmentKey {

    /// `nil` by default: the presentation root (`WorkflowPaywallView` for workflows,
    /// `PaywallsV2View` for standalone paywalls) injects the session's store.
    static let defaultValue: PaywallStateStore? = nil

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallStateStore: PaywallStateStore? {
        get { self[PaywallStateStoreKey.self] }
        set { self[PaywallStateStoreKey.self] = newValue }
    }

}

// MARK: - State snapshot environment values

/// The presentation root injects the state store's *current values* and *declared defaults* as
/// plain environment values, recomputed whenever the store publishes a change (the root observes
/// the store via `@StateObject`). Override-resolving component views read these to feed
/// `ConditionContext`, and — because reading an environment value subscribes the view to it —
/// re-resolve their overrides whenever a state update changes the snapshot. This is the
/// "redraw via environment value" path: the object itself is not observed by the leaf views
/// (it is exposed only as the optional `paywallStateStore` key), so unrelated state writes never
/// invalidate views that don't read the values.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateValuesKey: EnvironmentKey {
    static let defaultValue: [String: PaywallComponent.ConditionValue] = [:]
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateDefaultsKey: EnvironmentKey {
    static let defaultValue: [String: PaywallComponent.ConditionValue] = [:]
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Current values of declared state keys for the presentation session.
    var paywallStateValues: [String: PaywallComponent.ConditionValue] {
        get { self[PaywallStateValuesKey.self] }
        set { self[PaywallStateValuesKey.self] = newValue }
    }

    /// Declared defaults for state keys, used when a key has no value in the current snapshot.
    var paywallStateDefaults: [String: PaywallComponent.ConditionValue] {
        get { self[PaywallStateDefaultsKey.self] }
        set { self[PaywallStateDefaultsKey.self] = newValue }
    }

}

#endif
