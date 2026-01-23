//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallVariables.swift
//
//  Created by Facundo Menzella on 1/22/26.

import SwiftUI

/// A value type for custom paywall variables that can be passed to paywalls at runtime.
///
/// Custom variables allow developers to personalize paywall text with dynamic values.
/// Variables are defined in the RevenueCat dashboard and can be overridden at runtime.
///
/// ### Usage
/// ```swift
/// PaywallView()
///     .customPaywallVariables([
///         "player_name": .string("John"),
///         "max_health": .number(100),
///         "is_premium": .bool(true)
///     ])
/// ```
///
/// In the paywall text (configured in the dashboard), use the `custom.` prefix:
/// ```
/// Hello {{ custom.player_name }}!
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public enum CustomVariableValue: Sendable, Equatable, Hashable {

    /// A string value.
    case string(String)

    /// A numeric value.
    case number(Double)

    /// A boolean value.
    case bool(Bool)

    /// The string representation of this value for use in paywall text replacement.
    public var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            // Format nicely: 100.0 -> "100", 99.99 -> "99.99"
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", value)
            } else {
                return String(value)
            }
        case .bool(let value):
            return value ? "true" : "false"
        }
    }

    /// The numeric representation of this value.
    /// Returns the underlying value for `.number`, attempts conversion for `.string`,
    /// and returns `1.0` for `true` or `0.0` for `false` in `.bool` cases.
    public var doubleValue: Double {
        switch self {
        case .string(let value):
            return Double(value) ?? 0
        case .number(let value):
            return value
        case .bool(let value):
            return value ? 1.0 : 0.0
        }
    }

    /// The boolean representation of this value.
    /// Returns the underlying value for `.bool`, `true` for non-zero `.number`,
    /// and `true` for non-empty `.string` (case-insensitive "true", "1", "yes").
    public var boolValue: Bool {
        switch self {
        case .string(let value):
            let lowercased = value.lowercased()
            return lowercased == "true" || lowercased == "1" || lowercased == "yes"
        case .number(let value):
            return value != 0
        case .bool(let value):
            return value
        }
    }

}

// MARK: - ExpressibleByStringLiteral

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue: ExpressibleByStringLiteral {

    /// Creates a custom variable value from a string literal.
    public init(stringLiteral value: String) {
        self = .string(value)
    }

}

// MARK: - ExpressibleByIntegerLiteral

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue: ExpressibleByIntegerLiteral {

    /// Creates a custom variable value from an integer literal.
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }

}

// MARK: - ExpressibleByFloatLiteral

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue: ExpressibleByFloatLiteral {

    /// Creates a custom variable value from a floating-point literal.
    public init(floatLiteral value: Double) {
        self = .number(value)
    }

}

// MARK: - ExpressibleByBooleanLiteral

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue: ExpressibleByBooleanLiteral {

    /// Creates a custom variable value from a boolean literal.
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

}

// MARK: - Environment Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CustomPaywallVariablesKey: EnvironmentKey {

    static let defaultValue: [String: CustomVariableValue] = [:]

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Custom variables to be used in paywall text replacement.
    ///
    /// Use the `.customPaywallVariables(_:)` view modifier to set this value.
    public var customPaywallVariables: [String: CustomVariableValue] {
        get { self[CustomPaywallVariablesKey.self] }
        set { self[CustomPaywallVariablesKey.self] = newValue }
    }

}

// MARK: - View Modifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Sets custom variables to be used in paywall text replacement.
    ///
    /// Custom variables allow you to personalize paywall text with dynamic values.
    /// Variables are defined in the RevenueCat dashboard using the `{{ custom.key }}` syntax.
    ///
    /// ### Example
    /// ```swift
    /// PaywallView()
    ///     .customPaywallVariables([
    ///         "player_name": .string("John"),
    ///         "max_health": .number(100),
    ///         "is_premium": .bool(true)
    ///     ])
    /// ```
    ///
    /// You can also apply this modifier at any ancestor view level:
    /// ```swift
    /// NavigationStack {
    ///     ContentView()  // PaywallView somewhere inside
    /// }
    /// .customPaywallVariables(["player_name": .string(user.name)])
    /// ```
    ///
    /// - Parameter variables: A dictionary mapping variable names to their values.
    ///   The keys should match the variable names defined in the dashboard (without the `custom.` prefix).
    /// - Returns: A view with the custom variables set in the environment.
    public func customPaywallVariables(
        _ variables: [String: CustomVariableValue]
    ) -> some View {
        environment(\.customPaywallVariables, variables)
    }

}

// MARK: - Helper to convert to string dictionary

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Dictionary where Key == String, Value == CustomVariableValue {

    /// Converts the custom variables dictionary to a string dictionary for internal use.
    var asStringDictionary: [String: String] {
        self.mapValues { $0.stringValue }
    }

}
