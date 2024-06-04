//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2Receipt.swift
//
//  Created by MarkVillacampa on 26/10/23.

import StoreKit

/// A type that resembles the structure of a StoreKit 1 receipt using StoreKit 2 data.
struct StoreKit2Receipt: Equatable {

    struct SubscriptionState: RawRepresentable, Equatable {

        let rawValue: Int

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let subscribed = Self(rawValue: 1)
        static let expired = Self(rawValue: 2)
        static let inBillingRetryPeriod = Self(rawValue: 3)
        static let inGracePeriod = Self(rawValue: 4)
        static let revoked = Self(rawValue: 5)

    }

    struct SubscriptionStatus: Equatable {

        /// The renewal state of the auto-renewable subscription.
        let state: SubscriptionState

        /// JWS token of the renewal information.
        let renewalInfoJWSToken: String

        /// JWS token of the latest transaction for the subscription group.
        let transactionJWSToken: String

    }

    /// The server environment where the receipt was generated.
    let environment: StoreEnvironment

    /// The current subscription status for each subscription group, including the renewal information.
    let subscriptionStatusBySubscriptionGroupId: [String: [SubscriptionStatus]]

    /// The list of transaction JWS tokens purchased by the customer.
    let transactions: [String]

    /// The bundle identifier of the app.
    let bundleId: String

    /// The app version that the user originally purchased from the App Store.
    let originalApplicationVersion: String?

    /// The date the user originally purchased the app from the App Store.
    let originalPurchaseDate: Date?

}

// MARK: -

extension StoreKit2Receipt.SubscriptionState: Codable {}

extension StoreKit2Receipt.SubscriptionState {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    static func from(state: StoreKit.Product.SubscriptionInfo.RenewalState) -> Self {
        switch state {
        case .subscribed:
            return .subscribed
        case .expired:
            return .expired
        case .inBillingRetryPeriod:
            return .inBillingRetryPeriod
        case .inGracePeriod:
            return .inGracePeriod
        case .revoked:
            return .revoked
        default:
            return .init(rawValue: state.rawValue)
        }
    }

}

extension StoreKit2Receipt.SubscriptionStatus: Codable {

    private enum CodingKeys: String, CodingKey {
        case state
        case renewalInfoJWSToken = "renewal_info"
        case transactionJWSToken = "transaction"
    }

}

extension StoreKit2Receipt: Codable {

    private enum CodingKeys: String, CodingKey {
        case environment
        case subscriptionStatusBySubscriptionGroupId = "subscription_status"
        case transactions
        case bundleId = "bundle_id"
        case originalApplicationVersion = "original_application_version"
        case originalPurchaseDate = "original_purchase_date"
    }

}
