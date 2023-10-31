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

    /// The server environment where the receipt was generated.
    let environment: StoreEnvironment

    /// The current subscription status for each subscription group, including the renewal information.
    /// The keys of the dictionary represent Subscription Group Identifiers, where the values are arrays 
    /// of JWS tokens of the renewal information.
    let subscriptionStatus: [String: [String]]

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

extension StoreKit2Receipt: Codable {

    private enum CodingKeys: String, CodingKey {
        case environment
        case subscriptionStatus = "subscription_status"
        case transactions
        case bundleId = "bundle_id"
        case originalApplicationVersion = "original_application_version"
        case originalPurchaseDate = "original_purchase_date"
    }

}
