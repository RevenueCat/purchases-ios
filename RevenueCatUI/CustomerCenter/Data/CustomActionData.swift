//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomActionData.swift
//
//  Created by Facundo Menzella on 21/07/2025.
//

import Foundation

/// Data associated with a custom action selection in the Customer Center.
/// 
/// This struct encapsulates information about a custom action that has been triggered
/// by a user interaction in the Customer Center. Custom actions are defined in the
/// Customer Center configuration and allow applications to handle specialized user
/// flows beyond the standard Customer Center actions.
///
/// ## Usage
/// 
/// Custom actions are handled through the SwiftUI view modifier:
/// 
/// ```swift
/// CustomerCenterView()
///     .onCustomerCenterCustomActionSelected { actionIdentifier, purchaseIdentifier in
///         // Handle the custom action
///         switch actionIdentifier {
///         case "delete_user":
///             deleteUserAccount()
///         case "rate_app":
///             showAppStoreRating()
///         default:
///             break
///         }
///     }
/// ```
public struct CustomActionData {

    /// The unique identifier for the custom action.
    /// 
    /// This identifier is configured in the Customer Center dashboard and allows
    /// applications to distinguish between different types of custom actions.
    /// Common examples might include:
    /// - `"delete_user"`
    /// - `"rate_app"`
    /// - `"contact_support"`
    /// - `"view_privacy_settings"`
    public let actionIdentifier: String

    /// The product identifier of the purchase being viewed in a detail screen, if any.
    /// 
    /// This provides context about which specific purchase the custom action relates to.
    /// It will be `nil` if the custom action was triggered from the general management screen
    /// rather than from a specific purchase detail screen.
    /// 
    /// - When triggered from a purchase detail screen: Contains the product identifier of that purchase
    /// - When triggered from the management screen: Will be `nil`
    public let purchaseIdentifier: String?

    /// Creates a new `CustomActionData` instance.
    /// 
    /// - Parameters:
    ///   - actionIdentifier: The unique identifier for the custom action
    ///   - purchaseIdentifier: The unique identifier of a purchase
    public init(actionIdentifier: String, purchaseIdentifier: String?) {
        self.actionIdentifier = actionIdentifier
        self.purchaseIdentifier = purchaseIdentifier
    }
}

// MARK: - Equatable

extension CustomActionData: Equatable {

    /// Returns a Boolean value indicating whether two `CustomActionData` instances are equal.
    /// 
    /// Two `CustomActionData` instances are considered equal if both their `actionIdentifier` 
    /// and `purchaseIdentifier` properties are equal.
    ///
    /// - Parameters:
    ///   - lhs: A `CustomActionData` instance to compare.
    ///   - rhs: Another `CustomActionData` instance to compare.
    /// - Returns: `true` if the instances are equal; otherwise, `false`.
    public static func == (lhs: CustomActionData, rhs: CustomActionData) -> Bool {
        return lhs.actionIdentifier == rhs.actionIdentifier &&
               lhs.purchaseIdentifier == rhs.purchaseIdentifier
    }
}

// MARK: - Hashable

extension CustomActionData: Hashable {

    /// Hashes the essential components of this `CustomActionData` by feeding them into the given hasher.
    /// 
    /// This method combines the `actionIdentifier` and `purchaseIdentifier` properties 
    /// to generate a hash value for the instance.
    /// 
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(actionIdentifier)
        hasher.combine(purchaseIdentifier)
    }
}

// MARK: - CustomStringConvertible

extension CustomActionData: CustomStringConvertible {

    /// A textual representation of this `CustomActionData` instance.
    /// 
    /// The description includes the action identifier and information about the 
    /// associated purchase, if any. This is useful for debugging and logging purposes.
    /// 
    /// - Returns: A string describing the custom action data.
    public var description: String {
        let purchaseInfo = purchaseIdentifier.map { "purchase: \($0)" } ?? "no active purchase"
        return "CustomActionData(actionIdentifier: \"\(actionIdentifier)\", \(purchaseInfo))"
    }
}
