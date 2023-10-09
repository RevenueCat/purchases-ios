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
import RevenueCat

var entitlementInfo: EntitlementInfo!
func checkEntitlementInfoAPI() {
    let ident: String = entitlementInfo.identifier
    let isActive: Bool = entitlementInfo.isActive
    let isActiveInAnyEnvironment: Bool = entitlementInfo.isActiveInAnyEnvironment
    let isActiveInCurrentEnvironment: Bool = entitlementInfo.isActiveInCurrentEnvironment
    let willRenew: Bool = entitlementInfo.willRenew
    let pType: PeriodType = entitlementInfo.periodType
    let lpd: Date? = entitlementInfo.latestPurchaseDate
    let opd: Date? = entitlementInfo.originalPurchaseDate
    let eDate: Date? = entitlementInfo.expirationDate
    let store: Store = entitlementInfo.store
    let pId: String = entitlementInfo.productIdentifier
    let ppId: String? = entitlementInfo.productPlanIdentifier
    let iss: Bool = entitlementInfo.isSandbox
    let uda: Date? = entitlementInfo.unsubscribeDetectedAt
    let bida: Date? = entitlementInfo.billingIssueDetectedAt
    let oType: PurchaseOwnershipType = entitlementInfo.ownershipType

    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
        let _: VerificationResult = entitlementInfo.verification
    }

    let rawData: [String: Any] = entitlementInfo.rawData

    print(entitlementInfo!, ident, isActive, isActiveInAnyEnvironment, isActiveInCurrentEnvironment,
          willRenew, pType, lpd!, opd!, eDate!, store, pId, ppId!, iss, uda!, bida!, oType, rawData)
}

var store: Store!
var pType: PeriodType!
func checkEntitlementInfoEnums() {
    switch store! {
    case .appStore,
         .macAppStore,
         .playStore,
         .stripe,
         .promotional,
         .amazon,
         .unknownStore:
        print(store!)
    @unknown default:
        fatalError()
    }

    switch pType! {
    case .intro,
         .trial,
         .normal:
        print(pType!)
    @unknown default:
        fatalError()
    }
}
