//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigData.HelpPath+PurchaseInformation.swift
//
//  Created by Facundo Menzella on 23/5/25.

import Foundation
@_spi(Internal) import RevenueCat

extension Array<CustomerCenterConfigData.HelpPath> {
    func relevantPaths(
        for purchaseInformation: PurchaseInformation?,
        allowMissingPurchase: Bool
    ) -> [CustomerCenterConfigData.HelpPath] {
        guard let purchaseInformation else {
            return filter {
                $0.type == .missingPurchase
                    || $0.type == .customAction
                    || $0.type == .customUrl
            }
        }

        return filter {
            // we don't show missing purchase when a purchase is selected
            if !allowMissingPurchase && $0.type == .missingPurchase {
                return false
            }

            let isNonAppStorePurchase = purchaseInformation.store != .appStore
            let isAppStoreOnlyPath = $0.type.isAppStoreOnly

            // skip AppStore only paths if the purchase is not from App Store
            if isNonAppStorePurchase && isAppStoreOnlyPath {
                return false
            }

            if $0.type == .cancel {
                // don't show cancel if there's no URL
                if isNonAppStorePurchase {
                    return purchaseInformation.managementURL != nil
                }

                return purchaseInformation.isAppStoreRenewableSubscription
                    && !purchaseInformation.isCancelled
                    && purchaseInformation.renewalDate != nil
            }

            // if it's refundRequest, it cannot be free nor within trial period
            // if it has a refundDuration, check it's still valid
            if $0.type == .refundRequest {
                return purchaseInformation.pricePaid != .free
                && !purchaseInformation.isTrial
                && $0.refundWindowDuration?.isWithin(purchaseInformation) ?? true
            }

            // can't change plans if it's not a subscription
            if $0.type == .changePlans {
                if !purchaseInformation.isAppStoreRenewableSubscription || purchaseInformation.isLifetime {
                    return false
                }
            }

            return true
        }
    }
}

private extension CustomerCenterConfigData.HelpPath.PathType {

    var isAppStoreOnly: Bool {
        switch self {
        case .cancel, .customUrl, .customAction:
            return false

        case .changePlans, .refundRequest, .missingPurchase, .unknown:
            return true

        @unknown default:
            return false
        }
    }
}

private extension CustomerCenterConfigData.HelpPath.RefundWindowDuration {
    func isWithin(_ purchaseInformation: PurchaseInformation) -> Bool {
        switch self {
        case .forever:
            return true

        case let .duration(duration):
            return duration.isWithin(
                from: purchaseInformation.latestPurchaseDate,
                now: purchaseInformation.customerInfoRequestedDate
            )

        @unknown default:
            return true
        }
    }
}

private extension ISODuration {
    func isWithin(from startDate: Date?, now: Date) -> Bool {
        guard let startDate else {
            return true
        }

        var dateComponents = DateComponents()
        dateComponents.year = self.years
        dateComponents.month = self.months
        dateComponents.weekOfYear = self.weeks
        dateComponents.day = self.days
        dateComponents.hour = self.hours
        dateComponents.minute = self.minutes
        dateComponents.second = self.seconds

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: dateComponents, to: startDate) ?? startDate

        return startDate < endDate && now <= endDate
    }
}
