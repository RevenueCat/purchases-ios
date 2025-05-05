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
//  Created by Facundo Menzella on 5/5/25.

import Foundation
import RevenueCat

protocol Transaction {

    var productIdentifier: String { get }
    var store: Store { get }
    var type: TransactionType { get }
    var isCancelled: Bool { get }
}

enum TransactionType {

    case subscription(isActive: Bool, willRenew: Bool, expiresDate: Date?, isTrial: Bool)
    case nonSubscription
}
