//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfoAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases

func checkEntitlementInfoAPI() {
    let entitlementInfo = EntitlementInfo(entitlementId: "", entitlementData: [:], productData: [:], requestDate: nil)
    let ident: String = entitlementInfo.identifier
    let isActive: Bool = entitlementInfo.isActive
    let willRenew: Bool = entitlementInfo.willRenew
    let pType: PeriodType = entitlementInfo.periodType
    let lpd = entitlementInfo.latestPurchaseDate
    let opd: Date? = entitlementInfo.originalPurchaseDate
    let eDate: Date? = entitlementInfo.expirationDate
    let store: Store = entitlementInfo.store
    let pId: String = entitlementInfo.productIdentifier
    let iss: Bool = entitlementInfo.isSandbox
    let uda: Date? = entitlementInfo.unsubscribeDetectedAt
    let bida: Date? = entitlementInfo.billingIssueDetectedAt
    let oType: PurchaseOwnershipType = entitlementInfo.ownershipType

    print(entitlementInfo, ident, isActive, willRenew, pType, lpd ?? "noDate", opd ?? "noDate", eDate!, store, pId, iss, uda!, bida!, oType)
}

func checkEntitlementInfoEnums() {
    var store: Store = Store.appStore
    store = Store.macAppStore
    store = Store.playStore
    store = Store.stripe
    store = Store.promotional
    store = Store.unknownStore

    var pType: PeriodType = .intro
    pType = .trial
    pType = .normal

    print(store, pType)
}
