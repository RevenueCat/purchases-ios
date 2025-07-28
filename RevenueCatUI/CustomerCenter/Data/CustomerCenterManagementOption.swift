//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterManagementOption.swift
//
//  Created by Cesar de la Vega on 11/3/25.

import Foundation

/// Protocol for action types that can be handled by the Customer Center
public protocol CustomerCenterActionable {}

/// Management options that can be triggered by buttons in the Customer Center
public enum CustomerCenterManagementOption {
    /// Represents a cancel action
    public struct Cancel: CustomerCenterActionable {}

    /// Represents an action to open a custom URL
    public struct CustomUrl: CustomerCenterActionable {
        /// The URL that will be opened
        public let url: URL
    }

    /// Represents a missing purchase (restore) action
    public struct MissingPurchase: CustomerCenterActionable {}

    /// Represents a refund request action
    public struct RefundRequest: CustomerCenterActionable {}

    /// Represents a change plans action
    public struct ChangePlans: CustomerCenterActionable {}

    /// Represents a custom action
    public struct CustomAction: CustomerCenterActionable {
        /// The custom action identifier
        public let actionIdentifier: String
        /// The optional active purchase ID
        public let purchaseIdentifier: String?

        /// Creates a new `CustomAction` instance.
        /// 
        /// - Parameters:
        ///   - actionIdentifier: The unique identifier for the custom action
        ///   - purchaseIdentifier: The optional product identifier of the active purchase
        public init(actionIdentifier: String, purchaseIdentifier: String?) {
            self.actionIdentifier = actionIdentifier
            self.purchaseIdentifier = purchaseIdentifier
        }
    }

}
