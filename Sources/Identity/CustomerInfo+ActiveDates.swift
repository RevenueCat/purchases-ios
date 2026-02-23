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
                            let key = Self.extractProductIDAndBasePlan(from: productID, purchase: subscription)
                            let value = subscription.expiresDate
                            return (key, value)
                        }
                )
    }

    static func extractPurchaseDates(_ subscriber: CustomerInfoResponse.Subscriber) -> [String: Date?] {
        // We map each raw purchase key through `extractProductIDAndBasePlan`.
        // Different source keys can collapse to the same mapped key (for example, base-plan and already-composed IDs),
        // so we keep the best candidate per mapped key instead of crashing on duplicates.
        struct PurchaseDateCandidate {
            let purchaseDate: Date?
            let hasGoogleStyleProductID: Bool
            let hasSubscriptionMetadata: Bool
            let originalProductID: String
        }

        func preferredCandidate(_ lhs: PurchaseDateCandidate, _ rhs: PurchaseDateCandidate) -> PurchaseDateCandidate {
            // We determine a preferred purchase candidate if there is a conflict by looking at:
            // 1. Prefer a non-nil purchase date over a nil purchase date.
            // 2. If both dates exist, keep the most recent date.
            // 3. If dates are tied, prefer Google-style raw product IDs (`product:plan`).
            // 4. If still tied, prefer subscription-like data (expires date / base-plan metadata present).
            // 5. Final deterministic tiebreaker by original product ID in alphabetical order.
            switch (lhs.purchaseDate, rhs.purchaseDate) {
            case (.some, .none):
                return lhs
            case (.none, .some):
                return rhs
            case let (.some(lhsDate), .some(rhsDate)):
                if lhsDate != rhsDate {
                    return lhsDate > rhsDate ? lhs : rhs
                }
            case (.none, .none):
                break
            }

            if lhs.hasGoogleStyleProductID != rhs.hasGoogleStyleProductID {
                return lhs.hasGoogleStyleProductID ? lhs : rhs
            }

            if lhs.hasSubscriptionMetadata != rhs.hasSubscriptionMetadata {
                return lhs.hasSubscriptionMetadata ? lhs : rhs
            }

            return lhs.originalProductID <= rhs.originalProductID ? lhs : rhs
        }

        // Here, we use `uniquingKeysWith` instead of `uniqueKeysWithValues` to avoid
        // crashes when `extractProductIDAndBasePlan()` returns multiple products with the
        // same product ID, which can happen with Google subscriptions with base plans
        let merged = Dictionary(
            subscriber.allPurchasesByProductId.map { productID, purchase in
                let key = Self.extractProductIDAndBasePlan(from: productID, purchase: purchase)
                let candidate = PurchaseDateCandidate(
                    purchaseDate: purchase.purchaseDate,
                    hasGoogleStyleProductID: productID.contains(":"),
                    hasSubscriptionMetadata: purchase.expiresDate != nil || purchase.productPlanIdentifier != nil,
                    originalProductID: productID
                )
                return (key, candidate)
            },
            uniquingKeysWith: preferredCandidate
        )

        return merged.mapValues(\.purchaseDate)
    }

}

// MARK: - Private

private extension CustomerInfo {

    static func extractProductIDAndBasePlan(from productID: String,
                                            purchase: CustomerInfoResponse.Subscription) -> String {
        // Products purchased from Google Play will have a product plan identifier (base plan)
        // These products get mapped as "productId:productPlanIdentifier" in the Android SDK
        // so the same mapping needs to be handled here for cross platform purchases
        if let productPlanIdentfier = purchase.productPlanIdentifier {
            return "\(productID):\(productPlanIdentfier)"
        } else {
            return productID
        }
    }

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
