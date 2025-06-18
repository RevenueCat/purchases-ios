//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInfo.swift
//
//
//  Created by Facundo Menzella on 15/1/25.
//

#if os(iOS)
@_spi(Internal) import RevenueCat
import SwiftUI

extension PurchaseInformation {

    @available(iOS 15.0, *)
    var purchaseDetailDebugItems: [PurchaseDetailItem] {
#if DEBUG
        debugItems
#else
        []
#endif
    }

    @available(iOS 15.0, *)
    func purchaseDetailItems(localization: CustomerCenterConfigData.Localization) -> [PurchaseDetailItem] {
        var items: [PurchaseDetailItem] = []
        items.append(.paidPrice(pricePaidString(localizations: localization)))
        items.append(.status(
            isExpired ? .inactive : .active
        ))

        let dateFormatter = PurchaseInformation.defaultDateFormatter
        if let expirationDate = expirationDate {
            items.append(.expiresDate(dateFormatter.string(from: expirationDate)))
        } else if let renewalDate = renewalDate {
            items.append(.nextRenewalDate(dateFormatter.string(from: renewalDate)))
        }

        if let unsubscribeDetectedAt = unsubscribeDetectedAt {
            items.append(.unsubscribeDetectedAt(dateFormatter.string(from: unsubscribeDetectedAt)))
        }

        if let billingIssuesDetectedAt = billingIssuesDetectedAt {
            items.append(.billingIssuesDetectedAt(dateFormatter.string(from: billingIssuesDetectedAt)))
        }

        if let gracePeriodExpiresDate = gracePeriodExpiresDate {
            items.append(.gracePeriodExpiresDate(dateFormatter.string(from: gracePeriodExpiresDate)))
        }

        if periodType != .normal {
            items.append(.periodType(
                periodType == .intro ? .introductoryPrice : .trialPeriod
            ))
        }

        if let refundedAt = refundedAtDate {
            items.append(.refundedAtDate(dateFormatter.string(from: refundedAt)))
        }

        items.append(.latestPurchaseDate(dateFormatter.string(from: latestPurchaseDate)))

        return items
    }
}

@available(iOS 15.0, *)
private extension PurchaseInformation {
    var debugItems: [PurchaseDetailItem] {
        var items: [PurchaseDetailItem] = [
            .store(storeLocalizationKey),
            .productID(productIdentifier),
            .sandbox(isSandbox)
        ]

        if let storeTransactionIdentifier {
            items.append(.transactionID(storeTransactionIdentifier))
        }

        let dateFormatter = PurchaseInformation.defaultDateFormatter
        if let originalPurchaseDate {
            items.append(.originalPurchaseDate(dateFormatter.string(from: originalPurchaseDate)))
        }

        return items
    }
}

#endif
