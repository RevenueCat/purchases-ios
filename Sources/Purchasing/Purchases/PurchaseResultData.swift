//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseResultData.swift
//
//  Created by Nacho Soto on 4/26/23.

import Foundation

/// Result for ``Purchases/purchase(product:)``.
/// Counterpart of `PurchaseCompletedBlock` for `async` APIs.
public struct PurchaseResultData {

    /// The transaction from this purchase.
    public let transaction: StoreTransaction?
    /// The ``CustomerInfo`` with updated entitlements after a purchase.
    public let customerInfo: CustomerInfo

    // swiftlint:disable:next identifier_name
    internal let _userCancelled: Bool

    // swiftlint:disable:next missing_docs
    public init(transaction: StoreTransaction?, customerInfo: CustomerInfo, userCancelled: Bool) {
        self.init(transaction, customerInfo, userCancelled)
    }

}

extension PurchaseResultData {

    internal init(_ transaction: StoreTransaction?, _ customerInfo: CustomerInfo, _ userCancelled: Bool) {
        self.transaction = transaction
        self.customerInfo = customerInfo
        self._userCancelled = userCancelled
    }

}

public extension PurchaseResultData {

    #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    @available(
        *, unavailable,
        message: "To detect cancellations, you need to catch `ErrorCode.purchaseCancelledError instead"
    )
    // swiftlint:disable:next missing_docs
    var userCancelled: Bool { self._userCancelled }
    #else
    /// Whether the user cancelled the purchase.
    var userCancelled: Bool { self._userCancelled }
    #endif

}

extension PurchaseResultData: Sendable {}
