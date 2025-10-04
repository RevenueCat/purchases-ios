//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInfoAPI.swift
//
//  Created by Cesar de la Vega on 26/11/24.

import Foundation
import RevenueCat

var subscription: SubscriptionInfo!
func checkSubscriptionInfoAPI() {
    let pId: String = subscription.productIdentifier
    let pIdP: ProductIdentifier = subscription.productIdentifier
    let pd: Date = subscription.purchaseDate
    let opd: Date? = subscription.originalPurchaseDate
    let eDate: Date? = subscription.expiresDate
    let store: Store = subscription.store
    let iss: Bool = subscription.isSandbox
    let uda: Date? = subscription.unsubscribeDetectedAt
    let bida: Date? = subscription.billingIssuesDetectedAt
    let gped: Date? = subscription.gracePeriodExpiresDate
    let oType: PurchaseOwnershipType = subscription.ownershipType
    let pType: PeriodType = subscription.periodType
    let rAt: Date? = subscription.refundedAt
    let txId: String? = subscription.storeTransactionId
    let isActive: Bool = subscription.isActive
    let willRenew: Bool = subscription.willRenew
    let displayName: String? = subscription.displayName
    let managementURL: URL? = subscription.managementURL
}
