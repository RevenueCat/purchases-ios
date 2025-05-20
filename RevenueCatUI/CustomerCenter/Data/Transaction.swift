//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Transaction.swift
//
//  Created by Facundo Menzella on 12/5/25.

import Foundation
@_spi(Internal) import RevenueCat

protocol Transaction {

    var productIdentifier: String { get }
    var store: Store { get }
    var type: TransactionType { get }
    var isCancelled: Bool { get }
    var managementURL: URL? { get }
    var price: ProductPaidPrice? { get }
    var periodType: PeriodType { get }
}

enum TransactionType {

    case subscription(isActive: Bool, willRenew: Bool, expiresDate: Date?, isTrial: Bool)
    case nonSubscription
}

@_spi(Internal) extension RevenueCat.SubscriptionInfo: Transaction {

    var type: TransactionType {
        .subscription(isActive: isActive,
                      willRenew: willRenew,
                      expiresDate: expiresDate,
                      isTrial: periodType == .trial)
    }

    var isCancelled: Bool {
        unsubscribeDetectedAt != nil && !willRenew
    }

}

extension NonSubscriptionTransaction: Transaction {

    var type: TransactionType {
        .nonSubscription
    }

    var isCancelled: Bool {
        false
    }

    var managementURL: URL? {
        nil
    }

    var price: ProductPaidPrice? {
        // We don't have that information in the CustomerInfo
        nil
    }

    var periodType: PeriodType {
        .normal
    }

}
