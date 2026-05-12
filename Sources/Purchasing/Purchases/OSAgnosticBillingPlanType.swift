//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OSAgnosticBillingPlanType.swift
//
//  Created by Will Taylor on 5/12/26.

import Foundation

/// A StoreKit billing plan type represented without directly referencing newer StoreKit symbols.
///
/// This lets code that does not compile against StoreKit billing plan APIs still pass around the billing plans,
/// while the StoreKit-specific mappings stay gated behind compiler and OS availability checks.
internal enum OSAgnosticBillingPlanType {

    /// The customer pays the full commitment price when the subscription starts.
    case upFront

    /// The customer pays the commitment price in monthly installments.
    case monthly
}

#if compiler(>=6.3.2)
internal extension OSAgnosticBillingPlanType {

    /// Creates an OS-agnostic billing plan type from a StoreKit 2 billing plan type.
    ///
    /// Returns `nil` when StoreKit provides a unsupported billing plan type.
    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    static func fromSKBillingPlanType(_ skBillingPlanType: SK2BillingPlanType) -> OSAgnosticBillingPlanType? {
        switch skBillingPlanType {
        case .upFront:
            return .upFront
        case .monthly:
            return .monthly
        default:
            return nil
        }
    }

    /// The billing plan type represented by the OS-agnostic value.
    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    var skBillingPlanType: SK2BillingPlanType {
        switch self {
        case .upFront:
            return .upFront
        case .monthly:
            return .monthly
        }
    }
}
#endif
