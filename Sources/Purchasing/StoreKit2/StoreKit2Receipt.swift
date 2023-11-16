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

    struct SubscriptionStatus: Equatable {
        /// Subscription Group Identifiers.
        let subscriptionGroupId: String
        /// JWS tokens of the renewal information.
        let renewalInfoJWSTokens: [String]
    }

    /// The server environment where the receipt was generated.
    let environment: StoreEnvironment

    /// The current subscription status for each subscription group, including the renewal information.
    let subscriptionStatus: [SubscriptionStatus]

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

extension StoreKit2Receipt.SubscriptionStatus: Encodable {}

extension StoreKit2Receipt: Encodable {

    private enum CodingKeys: String, CodingKey {
        case environment
        case subscriptionStatus = "subscription_status"
        case transactions
        case bundleId = "bundle_id"
        case originalApplicationVersion = "original_application_version"
        case originalPurchaseDate = "original_purchase_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.environment, forKey: .environment)
        try container.encode(self.transactions, forKey: .transactions)
        try container.encode(self.bundleId, forKey: .bundleId)
        try container.encode(self.originalApplicationVersion, forKey: .originalApplicationVersion)
        try container.encode(self.originalPurchaseDate, forKey: .originalPurchaseDate)
        let statuses = Dictionary(self.subscriptionStatus.map {
            ($0.subscriptionGroupId, $0.renewalInfoJWSTokens)
        }) { _, new in new }

        try container.encode(statuses, forKey: .subscriptionStatus)
    }

}
