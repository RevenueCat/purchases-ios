//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

/**
 * Configures how RevenueCat should handle a purchase that is already associated with another App User ID.
 *
 * See [the RevenueCat docs](https://www.revenuecat.com/docs/projects/restore-behavior) for more information.
 */
@objc(RCTransferBehavior)
public final class TransferBehavior: NSObject, Sendable {

    /// Transfer the purchase to the current App User ID.
    @objc(RCTransferToNewAppUserID)
    public static let transferToNewAppUserID = TransferBehavior(rawValue: "transfer_to_new_app_user_id")

    /// Transfer the purchase only if the original App User ID has no active subscriptions.
    @objc(RCTransferIfNoActiveSubscriptions)
    public static let transferIfNoActiveSubscriptions = TransferBehavior(
        rawValue: "transfer_if_no_active_subscriptions"
    )

    /// Keep the purchase with the original App User ID.
    @objc(RCKeepWithOriginalAppUserID)
    public static let keepWithOriginalAppUserID = TransferBehavior(rawValue: "keep_with_original_app_user_id")

    /// String value sent to the RevenueCat backend.
    @objc public let rawValue: String

    internal init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TransferBehavior else { return false }

        return self.rawValue == other.rawValue
    }

    public override var hash: Int {
        return self.rawValue.hashValue
    }

    /// Pattern matching operator.
    public static func ~= (lhs: TransferBehavior, rhs: TransferBehavior) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

}

#else

/// This class is used for testing purposes only.
internal final class TransferBehavior: NSObject, Sendable {

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

}

#endif
