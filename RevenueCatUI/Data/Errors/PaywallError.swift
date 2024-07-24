//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywalError.swift
//
//  Created by Nacho Soto on 7/21/23.

import Foundation

/// Error produced when displaying paywalls.
enum PaywallError: Error {

    /// `Purchases` has not been configured yet.
    case purchasesNotConfigured

    /// RevenueCat dashboard does not have a current offering configured.
    case noCurrentOffering

    /// The selected offering was not found.
    case offeringNotFound(identifier: String)

    /// The PaywallView must be initialized with ``performPurchase`` and ``performRestore``
    /// when ``purchasesAreCompletedBy`` is ``.myApp``
    case performPurchaseAndRestoreHandlersNotDefined(missingBlocks: String)

    /// The PaywallView need not be initizlied with performPurchase and performRestore
    /// when ``purchasesAreCompletedBy`` is ``.revenueCat``
    case purchaseAndRestoreDefinedForRevenueCat

}

extension PaywallError: CustomNSError, CustomStringConvertible {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    var description: String {
        switch self {
        case .purchasesNotConfigured:
            return "Purchases instance has not been configured yet."

        case .noCurrentOffering:
            return "The RevenueCat dashboard does not have a current offering configured."

        case let .offeringNotFound(identifier):
            return "The RevenueCat dashboard does not have an offering with identifier '\(identifier)'."
        case .performPurchaseAndRestoreHandlersNotDefined:
            return "PaywallView has not been correctly initialized. purchasesAreCompletedBy is set to .myApp, and so " +
            "the PaywallView must be initialized with a PerformPurchase and PerformRestore handler."
        case .purchaseAndRestoreDefinedForRevenueCat:
            return "RevenueCat is configured with purchasesAreCompletedBy set to .revenueCat, but " +
            "the Paywall has purchase/restore blocks defined. These will NOT be executed. " +
            "Please set purchasesAreCompletedBy to .myApp if you wish to run these blocks " +
            "instead of RevenueCat's purchase/restore code."
        }
    }

}
