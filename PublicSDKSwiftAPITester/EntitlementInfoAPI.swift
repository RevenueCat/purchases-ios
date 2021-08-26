//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCEntitlementInfoAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases

func checkEntitlementInfoAPI() {
    let entitlementInfo = Purchases.EntitlementInfo()
    let ident: String = entitlementInfo.identifier
    let isActive: Bool = entitlementInfo.isActive
    let willRenew: Bool = entitlementInfo.willRenew
    let pType: Purchases.PeriodType = entitlementInfo.periodType
    let lpd = entitlementInfo.latestPurchaseDate
    let opd: Date = entitlementInfo.originalPurchaseDate
    let eDate: Date? = entitlementInfo.expirationDate
    let store: Purchases.Store = entitlementInfo.store
    let pId: String = entitlementInfo.productIdentifier
    let iss: Bool = entitlementInfo.isSandbox
    let uda: Date? = entitlementInfo.unsubscribeDetectedAt
    let bida: Date? = entitlementInfo.billingIssueDetectedAt
    let oType: RCPurchaseOwnershipType = entitlementInfo.ownershipType

    print(entitlementInfo, ident, isActive, willRenew, pType, lpd, opd, eDate!, store, pId, iss, uda!, bida!, oType)
}

func checkEntitlementInfoEnums() {
    var store: Purchases.Store = Purchases.Store.appStore
    store = Purchases.Store.macAppStore
    store = Purchases.Store.playStore
    store = Purchases.Store.stripe
    store = Purchases.Store.promotional
    store = Purchases.Store.unknownStore

    var pType: Purchases.PeriodType = Purchases.PeriodType.intro
    pType = Purchases.PeriodType.trial
    pType = Purchases.PeriodType.normal

    print(store, pType)
}
