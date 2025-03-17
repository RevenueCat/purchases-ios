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
    struct Cancel: CustomerCenterActionable {}

    /// Represents an action to open a custom URL
    struct CustomUrl: CustomerCenterActionable {
        let url: URL
    }

    /// Represents a missing purchase (restore) action
    struct MissingPurchase: CustomerCenterActionable {}

    /// Represents a refund request action
    struct RefundRequest: CustomerCenterActionable {}

    /// Represents a change plans action
    struct ChangePlans: CustomerCenterActionable {}
}
