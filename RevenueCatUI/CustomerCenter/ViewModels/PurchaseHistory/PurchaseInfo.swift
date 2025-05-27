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
import RevenueCat
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
            isActive ? .active : .inactive
        ))

        let dateFormatter = PurchaseInformation.defaultDateFormatter
        if let expirationDate = expirationDate {
            items.append(.expiresDate(dateFormatter.string(from: expirationDate)))
        } else if let renewalDate = renewalDate {
            items.append(.nextRenewalDate(dateFormatter.string(from: renewalDate)))
        }

//        if let unsubscribeDetectedAt = purchaseInfo.unsubscribeDetectedAt {
//            items.append(.unsubscribeDetectedAt(formattedDate(unsubscribeDetectedAt)))
//        }

        //            if let billingIssuesDetectedAt = purchaseInfo.billingIssuesDetectedAt {
        //                items.append(.billingIssuesDetectedAt(formattedDate(billingIssuesDetectedAt)))
        //            }

        //            if let gracePeriodExpiresDate = purchaseInfo.gracePeriodExpiresDate {
        //                items.append(.gracePeriodExpiresDate(formattedDate(gracePeriodExpiresDate)))
        //            }

        if periodType != .normal {
            items.append(.periodType(
                periodType == .intro ? .introductoryPrice : .trialPeriod
            ))
        }

        //            if let refundedAt = purchaseInfo.refundedAt {
        //                items.append(.refundedAtDate(formattedDate(refundedAt)))
        //            }

        //            items.append(.purchaseDate(formattedDate(transaction.purchaseDate)))

        return items
    }
}

@available(iOS 15.0, *)
private extension PurchaseInformation {
    var debugItems: [PurchaseDetailItem] {
        []
//        switch self {
//        case .subscription(let purchaseInfo):
//            var items: [PurchaseDetailItem] = [
//                .store(purchaseInfo.store.localizationKey),
//                .productID(purchaseInfo.productIdentifier),
//                .sandbox(purchaseInfo.isSandbox)
//            ]
//            if purchaseInfo.isActive {
//                if let originalPurchaseDate = purchaseInfo.originalPurchaseDate,
//                   originalPurchaseDate != purchaseInfo.purchaseDate {
//                    items.append(.purchaseDate(formattedDate(originalPurchaseDate)))
//                }
//            }
//
//            if let storeTransactionId = purchaseInfo.storeTransactionId {
//                items.append(.transactionID(storeTransactionId))
//            }
//            return items
//
//        case .nonSubscription(let transaction):
//            return [
//                .store(transaction.store.localizationKey),
//                .productID(transaction.productIdentifier),
//                .transactionID(transaction.storeTransactionIdentifier)
//            ]
//        }
    }
}

#endif
