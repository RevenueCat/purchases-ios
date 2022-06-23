//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat

var customerInfo: CustomerInfo!
func checkCustomerInfoAPI() {
    let entitlementInfo: EntitlementInfos = customerInfo.entitlements
    let asubs: Set<String> = customerInfo.activeSubscriptions
    let appis: Set<String> = customerInfo.allPurchasedProductIdentifiers
    let led: Date? = customerInfo.latestExpirationDate

    let nst: [NonSubscriptionTransaction] = customerInfo.nonSubscriptions
    let oav: String? = customerInfo.originalApplicationVersion
    let opd: Date? = customerInfo.originalPurchaseDate
    let rDate: Date? = customerInfo.requestDate
    let fSeen: Date = customerInfo.firstSeen
    let oaud: String? = customerInfo.originalAppUserId
    let murl: URL? = customerInfo.managementURL

    let edfpi: Date? = customerInfo.expirationDate(forProductIdentifier: "")
    let pdfpi: Date? = customerInfo.purchaseDate(forProductIdentifier: "")
    let exdf: Date? = customerInfo.expirationDate(forEntitlement: "")
    let pdfe: Date? = customerInfo.purchaseDate(forEntitlement: "")

    let desc: String = customerInfo.description

    let rawData: [String: Any] = customerInfo.rawData

    print(customerInfo!, entitlementInfo, asubs, appis, led!, nst, oav!, opd!, rDate!, fSeen, oaud!, murl!,
          edfpi!, pdfpi!, exdf!, pdfe!, desc, rawData)
}

func checkCacheFetchPolicyEnum(_ policy: CacheFetchPolicy) {
    switch policy {
    case .fromCacheOnly: break
    case .fetchCurrent: break
    case .cachedOrFetched: break
    case .notStaleCachedOrFetched: break

    @unknown default: break
    }
}

@available(*, deprecated) // Ignore deprecation warnings
func checkDeprecatedAPI() {
    let _: Set<String> = customerInfo.nonConsumablePurchases
    let _: [StoreTransaction] = customerInfo.nonSubscriptionTransactions
}
