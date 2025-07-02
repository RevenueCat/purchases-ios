//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTransaction.swift
//
//  Created by Facundo Menzella on 10/6/25.

import Foundation
import RevenueCat
@testable import RevenueCatUI

struct MockTransaction: Transaction {
    let productIdentifier: String
    let store: Store
    let type: TransactionType
    let isCancelled: Bool
    let managementURL: URL?
    let price: RevenueCat.ProductPaidPrice?
    let displayName: String?
    let periodType: RevenueCat.PeriodType
    let purchaseDate: Date
    var unsubscribeDetectedAt: Date?
    var billingIssuesDetectedAt: Date?
    var gracePeriodExpiresDate: Date?
    var refundedAtDate: Date?
    var storeIdentifier: String?
    var identifier: String?
    var originalPurchaseDate: Date?
    var isSandbox: Bool
    var isSubscrition: Bool
}
