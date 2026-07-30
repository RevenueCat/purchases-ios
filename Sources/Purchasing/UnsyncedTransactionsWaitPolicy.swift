//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UnsyncedTransactionsWaitPolicy.swift
//
//  Created by Álvaro Brey on 7/30/26.

import Foundation

/// Determines whether ``Purchases/customerInfo(fetchPolicy:)`` waits for unsynced transactions to be
/// posted to RevenueCat before completing.
///
/// When the SDK finds transactions that haven't been synced yet, it posts them and reports the
/// resulting ``CustomerInfo``. If posting is slow, every pending `customerInfo` call waits for it,
/// which can delay app launch when `customerInfo` gates the first screen.
@objc(RCUnsyncedTransactionsWaitPolicy)
public final class UnsyncedTransactionsWaitPolicy: NSObject {

    private let name: String

    private init(name: String) {
        self.name = name
        super.init()
    }

    /// Default behavior: ``CustomerInfo`` is reported once unsynced transactions have been posted.
    @objc public static let wait = UnsyncedTransactionsWaitPolicy(name: "wait")

    /// ``CustomerInfo`` is never held back by unsynced transactions: it is computed on the device
    /// while the transactions are posted in the background, and the up to date ``CustomerInfo`` is
    /// delivered through ``PurchasesDelegate/purchases(_:receivedUpdated:)`` once posting finishes.
    ///
    /// - Warning: the ``CustomerInfo`` reported while posting is in flight is computed from the
    /// device's transactions, so it is not verified by RevenueCat's servers, and purchases made
    /// outside of the store (web purchases, for example) are not included in it.
    /// - Note: this is best effort. When device side computation isn't possible, ``CustomerInfo``
    /// waits for the transactions to be posted, same as with ``wait``.
    @objc public static let doNotWait = UnsyncedTransactionsWaitPolicy(name: "do_not_wait")

    /// :nodoc:
    public override var description: String {
        return "\(type(of: self)).\(self.name)"
    }

}

// Immutable, and only ever the two constants above.
extension UnsyncedTransactionsWaitPolicy: @unchecked Sendable {}
