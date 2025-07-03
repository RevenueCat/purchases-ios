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
            }
        }

        return filter {
            // we don't show missing purchase when a purchase is selected
            if !allowMissingPurchase && $0.type == .missingPurchase {
                return false
            }

            let isNonAppStorePurchase = purchaseInformation.store != .appStore
            let isAppStoreOnlyPath = $0.type.isAppStoreOnly

            let isCancel = $0.type == .cancel

            // if it's cancel, it cannot be a lifetime subscription
            let isEligibleCancel = !purchaseInformation.isSubscription
                || (!purchaseInformation.isCancelled &&  !purchaseInformation.isLifetimeSubscription)

            // if it's refundRequest, it cannot be free nor within trial period
            let isRefund = $0.type == .refundRequest
            let isRefundEligible = purchaseInformation.pricePaid != .free
                                    && !purchaseInformation.isTrial
                                    && !purchaseInformation.isCancelled

            // if it has a refundDuration, check it's still valid
            let refundWindowIsValid = $0.refundWindowDuration?.isWithin(purchaseInformation) ?? true

            // skip AppStore only paths if the purchase is not from App Store
            if isNonAppStorePurchase && isAppStoreOnlyPath {
                return false
            }

            // don't show cancel if there's no URL
            if isCancel && isNonAppStorePurchase && purchaseInformation.managementURL == nil {
                 return false
            }

            // can't change plans if it's not a subscription or lifetime subscription
            if $0.type == .changePlans
                && (!purchaseInformation.isSubscription || purchaseInformation.isLifetimeSubscription) {
                return false
            }

            return (!isCancel || isEligibleCancel) &&
                    (!isRefund || isRefundEligible) &&
                    refundWindowIsValid
        }
    }
}

private extension CustomerCenterConfigData.HelpPath.PathType {

    var isAppStoreOnly: Bool {
        switch self {
        case .cancel, .customUrl:
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
