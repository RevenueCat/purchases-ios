//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseDetailItem.swift
//
//
//  Created by Facundo Menzella on 14/1/25.
//

import RevenueCat

typealias CSCommonLocalizedString = CustomerCenterConfigData.Localization.CommonLocalizedString

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum PurchaseDetailItem: Identifiable {
    case productName(String)
    case paidPrice(String?)
    case purchaseDate(String)
    case status(CSCommonLocalizedString)

    case nextRenewalDate(String)
    case expiresDate(String)
    case unsubscribeDetectedAt(String)
    case billingIssuesDetectedAt(String)
    case gracePeriodExpiresDate(String)
    case periodType(CSCommonLocalizedString)
    case refundedAtDate(String)

    // DEBUG only
    case store(String)
    case productID(String)
    case sandbox(Bool)
    case transactionID(String)

    var label: CSCommonLocalizedString {
        switch self {
        case .productName: return .productName
        case .paidPrice: return .paidPrice
        case .purchaseDate: return .originalDownloadDate
        case .status: return .status
        case .nextRenewalDate: return .nextRenewalDate
        case .expiresDate: return .expires
        case .unsubscribeDetectedAt: return .unsubscribedAt
        case .billingIssuesDetectedAt: return .billingIssueDetectedAt
        case .gracePeriodExpiresDate: return .gracePeriodExpiresAt
        case .periodType: return .periodType
        case .refundedAtDate: return .refundedAt
        case .store: return .store
        case .productID: return .productID
        case .sandbox: return .sandbox
        case .transactionID: return .transactionID
        }
    }

    var isDebugOnly: Bool {
        switch self {
        case .store, .productID, .sandbox, .transactionID:
            return true
        default:
            return false
        }
    }

    var id: String {
        label.rawValue
    }
}
