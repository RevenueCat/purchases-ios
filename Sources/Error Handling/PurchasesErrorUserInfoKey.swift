//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesErrorUserInfoKey.swift
//
//  Created by RevenueCat.
//

import Foundation

/// Contains keys that may be present in the `userInfo` dictionary of errors returned by the SDK.
@objc(RCPurchasesErrorUserInfoKey)
public final class PurchasesErrorUserInfoKey: NSObject {

    private override init() {
        super.init()
    }

    /// Key for `userInfo` indicating the purchase may have been interrupted by an external payment app.
    ///
    /// When this key is present and `true` in a ``ErrorCode/purchaseCancelledError``, the app was backgrounded
    /// during the purchase flow. This can occur when the user is redirected to an external payment app
    /// (e.g., UPI apps in India). In this case, the purchase may have actually succeeded.
    ///
    /// Developers should call ``Purchases/customerInfo()`` to verify the actual entitlement status
    /// when this key is present.
    @objc public static let purchaseWasBackgroundedKey: String =
        NSError.UserInfoKey.purchaseWasBackgroundedKey as String

}
