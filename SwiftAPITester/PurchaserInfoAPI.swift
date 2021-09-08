//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaserInfoAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases

var purchaserInfo: Purchases.PurchaserInfo!
func checkPurchaserInfoAPI() {
    let entitlementInfo: Purchases.EntitlementInfos = purchaserInfo.entitlements
    let asubs: Set<String> = purchaserInfo.activeSubscriptions
    let appis: Set<String> = purchaserInfo.allPurchasedProductIdentifiers
    let led: Date? = purchaserInfo.latestExpirationDate
    let ncp: Set<String> = purchaserInfo.nonConsumablePurchases
    let nst: [Purchases.Transaction] = purchaserInfo.nonSubscriptionTransactions
    let oav: String? = purchaserInfo.originalApplicationVersion
    let opd: Date? = purchaserInfo.originalPurchaseDate
    let rDate: Date? = purchaserInfo.requestDate
    let fSeen: Date = purchaserInfo.firstSeen
    let oaud: String? = purchaserInfo.originalAppUserId
    let murl: URL? = purchaserInfo.managementURL

    let edfpi: Date? = purchaserInfo.expirationDate(forProductIdentifier: "")
    let pdfpi: Date? = purchaserInfo.purchaseDate(forProductIdentifier: "")
    let exdf: Date? = purchaserInfo.expirationDate(forEntitlement: "")
    let pdfe: Date? = purchaserInfo.purchaseDate(forEntitlement: "")

    let desc: String = purchaserInfo.description

    print(purchaserInfo!, entitlementInfo, asubs, appis, led!, ncp, nst, oav!, opd!, rDate!, fSeen, oaud!, murl!,
          edfpi!, pdfpi!, exdf!, pdfe!, desc)
}
