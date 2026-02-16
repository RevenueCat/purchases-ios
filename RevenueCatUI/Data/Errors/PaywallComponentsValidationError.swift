//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentsValidationError.swift
//
//  Created by RevenueCat on 2/16/26.
//

import Foundation
import RevenueCat

/// Error produced when validating Paywalls V2 (components-based) paywall data.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallComponentsValidationError: Error {

    /// The paywall contains conditions that are not recognized by this SDK version.
    /// This triggers a fallback to the default paywall to prevent broken or unintended paywall states.
    case unsupportedConditionsFound

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponentsValidationError: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .unsupportedConditionsFound:
            return "Paywall contains conditions not recognized by this SDK version. " +
                   "Please update to the latest SDK version to display this paywall correctly."
        }
    }

}

// MARK: - Condition Validation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum ConditionValidator {

    /// Validates that no unsupported conditions exist in the component tree.
    /// - Parameter component: The root component to validate
    /// - Throws: `PaywallComponentsValidationError.unsupportedConditionsFound` if any unsupported condition is found
    static func validateConditions(in component: PaywallComponent) throws {
        if containsUnsupportedCondition(in: component) {
            Logger.error(Strings.paywall_contains_unsupported_condition)
            throw PaywallComponentsValidationError.unsupportedConditionsFound
        }
    }

    /// Validates that no unsupported conditions exist in the stack component.
    /// - Parameter stack: The stack component to validate
    /// - Throws: `PaywallComponentsValidationError.unsupportedConditionsFound` if any unsupported condition is found
    static func validateConditions(in stack: PaywallComponent.StackComponent) throws {
        if containsUnsupportedCondition(in: stack) {
            Logger.error(Strings.paywall_contains_unsupported_condition)
            throw PaywallComponentsValidationError.unsupportedConditionsFound
        }
    }

    /// Validates that no unsupported conditions exist in the components config.
    /// - Parameter config: The paywall components config to validate
    /// - Throws: `PaywallComponentsValidationError.unsupportedConditionsFound` if any unsupported condition is found
    static func validateConditions(in config: PaywallComponentsData.PaywallComponentsConfig) throws {
        // Validate main stack
        try validateConditions(in: config.stack)

        // Validate sticky footer if present
        if let stickyFooter = config.stickyFooter {
            try validateConditions(in: stickyFooter.stack)
        }
    }

    // MARK: - Private Helpers

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private static func containsUnsupportedCondition(in component: PaywallComponent) -> Bool {
        switch component {
        case .text(let component):
            return hasUnsupportedCondition(in: component.overrides)
        case .image(let component):
            return hasUnsupportedCondition(in: component.overrides)
        case .icon(let component):
            return hasUnsupportedCondition(in: component.overrides)
        case .stack(let component):
            return containsUnsupportedCondition(in: component)
        case .button(let component):
            // ButtonComponent doesn't have overrides, only check child stack
            if containsUnsupportedCondition(in: component.stack) {
                return true
            }
            if case let .navigateTo(.sheet(sheet)) = component.action {
                if containsUnsupportedCondition(in: sheet.stack) {
                    return true
                }
            }
            return false
        case .package(let component):
            // PackageComponent doesn't have overrides, only check child stack
            return containsUnsupportedCondition(in: component.stack)
        case .purchaseButton(let component):
            // PurchaseButtonComponent doesn't have overrides, only check child stack
            return containsUnsupportedCondition(in: component.stack)
        case .stickyFooter(let component):
            // StickyFooterComponent doesn't have overrides, only check child stack
            return containsUnsupportedCondition(in: component.stack)
        case .timeline(let component):
            if hasUnsupportedCondition(in: component.overrides) {
                return true
            }
            for item in component.items {
                if hasUnsupportedCondition(in: item.title.overrides) {
                    return true
                }
                if let description = item.description,
                   hasUnsupportedCondition(in: description.overrides) {
                    return true
                }
                if hasUnsupportedCondition(in: item.icon.overrides) {
                    return true
                }
            }
            return false
        case .tabs(let component):
            if hasUnsupportedCondition(in: component.overrides) {
                return true
            }
            if containsUnsupportedCondition(in: component.control.stack) {
                return true
            }
            for tab in component.tabs where containsUnsupportedCondition(in: tab.stack) {
                return true
            }
            return false
        case .tabControl:
            // TabControlComponent doesn't have overrides
            return false
        case .tabControlButton(let component):
            // TabControlButtonComponent doesn't have overrides, only check child stack
            return containsUnsupportedCondition(in: component.stack)
        case .tabControlToggle:
            // TabControlToggleComponent doesn't have overrides
            return false
        case .carousel(let component):
            if hasUnsupportedCondition(in: component.overrides) {
                return true
            }
            for page in component.pages where containsUnsupportedCondition(in: page) {
                return true
            }
            return false
        case .video(let component):
            return hasUnsupportedCondition(in: component.overrides)
        case .countdown(let component):
            if hasUnsupportedCondition(in: component.overrides) {
                return true
            }
            if containsUnsupportedCondition(in: component.countdownStack) {
                return true
            }
            if let endStack = component.endStack,
               containsUnsupportedCondition(in: endStack) {
                return true
            }
            if let fallback = component.fallback,
               containsUnsupportedCondition(in: fallback) {
                return true
            }
            return false
        }
    }

    private static func containsUnsupportedCondition(in stack: PaywallComponent.StackComponent) -> Bool {
        // Check stack's own overrides
        if hasUnsupportedCondition(in: stack.overrides) {
            return true
        }

        // Check badge if present
        if let badge = stack.badge,
           containsUnsupportedCondition(in: badge.stack) {
            return true
        }

        // Recursively check all children
        for child in stack.components where containsUnsupportedCondition(in: child) {
            return true
        }

        return false
    }

    private static func hasUnsupportedCondition<T: PaywallPartialComponent>(
        in overrides: PaywallComponent.ComponentOverrides<T>?
    ) -> Bool {
        guard let overrides else { return false }

        for override in overrides {
            for condition in override.conditions {
                if case .unsupported = condition {
                    return true
                }
            }
        }
        return false
    }

}
