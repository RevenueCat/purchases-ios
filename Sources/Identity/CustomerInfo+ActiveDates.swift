//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+ActiveDates.swift
//
//  Created by Nacho Soto on 3/7/23.

import Foundation

// MARK: - Internal

extension CustomerInfo {

    /// This grace period allows apps to continue functioning if the backend is down, but for a limited time.
    /// We don't want to continue granting entitlements with an outdated `requestDate` forever,
    /// since that would allow a user to get a free trial, then go offline and keep the entitlement with no time limit.
    static let requestDateGracePeriod: DispatchTimeInterval = .days(3)

    static func isDateActive(expirationDate: Date?, for requestDate: Date) -> Bool {
        guard let expirationDate = expirationDate else {
            return true
        }

        let (referenceDate, inGracePeriod) = Self.referenceDate(for: requestDate)
        let isActive = expirationDate.timeIntervalSince(referenceDate) >= 0

        if !inGracePeriod && !isActive {
            Logger.warn(Strings.purchase.entitlement_expired_outside_grace_period(expiration: expirationDate,
                                                                                  reference: requestDate))
        }

        return isActive
    }

    func activeKeys(dates: [String: Date?]) -> Set<String> {
        return Set(
            dates
                .lazy
                .filter { self.isDateActive($1) }
                .map { key, _ in key }
        )
    }

    static func extractExpirationDates(_ subscriber: CustomerInfoResponse.Subscriber) -> [String: Date?] {
        return Dictionary(
                    uniqueKeysWithValues: subscriber
                        .subscriptions
                        .lazy
                        .map { productID, subscription in
                            let key: String
                            let value = subscription.expiresDate

                            // Products purchased from Google Play will have a product plan identifier (base plan)
                            // These products get mapped as "productId:productPlanIdentifier" in the Android SDK
                            // so the same mapping needs to be handled here for cross platform purchases
                            if let productPlanIdentfier = subscription.productPlanIdentifier {
                                key = "\(productID):\(productPlanIdentfier)"
                            } else {
                                key = productID
                            }
                            return (key, value)
                        }
                )
    }

    static func extractPurchaseDates(_ subscriber: CustomerInfoResponse.Subscriber) -> [String: Date?] {
        return subscriber.allTransactionsByProductId.mapValues { $0.purchaseDate }
    }

}

// MARK: - Private

private extension CustomerInfo {

    static func referenceDate(for requestDate: Date) -> (Date, inGracePeriod: Bool) {
        if Date().timeIntervalSince(requestDate) <= Self.requestDateGracePeriod.seconds {
            return (requestDate, true)
        } else {
            return (Date(), false)
        }
    }

    func isDateActive(_ date: Date?) -> Bool {
        return Self.isDateActive(expirationDate: date, for: self.requestDate)
    }

}
