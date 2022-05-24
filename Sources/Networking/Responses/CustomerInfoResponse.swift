//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponse.swift
//
//  Created by Nacho Soto on 4/12/22.

import Foundation

struct CustomerInfoResponse {

    var requestDate: Date
    var subscriber: Subscriber

}

extension CustomerInfoResponse {

    struct Subscriber {

        var originalAppUserId: String
        @IgnoreDecodeErrors
        var managementUrl: URL?
        var originalApplicationVersion: String?
        var originalPurchaseDate: Date?
        var firstSeen: Date
        @DefaultDecodable.EmptyDictionary @LossyDictionary
        var subscriptions: [String: Subscription]
        @DefaultDecodable.EmptyDictionary @LossyArrayDictionary
        var nonSubscriptions: [String: [Transaction]]
        @DefaultDecodable.EmptyDictionary @LossyDictionary
        var entitlements: [String: Entitlement]

    }

    struct Subscription {

        @DefaultValue<PeriodType>
        var periodType: PeriodType
        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var expiresDate: Date?
        @DefaultValue<Store>
        var store: Store
        @DefaultDecodable.False
        var isSandbox: Bool
        var unsubscribeDetectedAt: Date?
        var billingIssuesDetectedAt: Date?
        @DefaultValue<PurchaseOwnershipType>
        var ownershipType: PurchaseOwnershipType

    }

    struct Transaction {

        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var transactionIdentifier: String?
        @DefaultValue<Store>
        var store: Store
        var isSandbox: Bool

    }

    struct Entitlement {

        var expiresDate: Date?
        var productIdentifier: String
        var purchaseDate: Date?

    }

}

// MARK: -

extension CustomerInfoResponse.Subscriber: Codable, Hashable {}
extension CustomerInfoResponse.Entitlement: Codable, Hashable {}
extension CustomerInfoResponse.Subscription: Codable, Hashable {}

extension CustomerInfoResponse.Transaction: Codable, Hashable {

    private enum CodingKeys: String, CodingKey {

        case purchaseDate
        case originalPurchaseDate
        case transactionIdentifier = "id"
        case store
        case isSandbox

    }

}

extension CustomerInfoResponse: Codable {}

// Equality + hash ignore request date.
extension CustomerInfoResponse: Equatable, Hashable {

    static func == (lhs: CustomerInfoResponse, rhs: CustomerInfoResponse) -> Bool {
        return lhs.subscriber == rhs.subscriber
    }

    func hash(into hasher: inout Hasher) {
        self.subscriber.hash(into: &hasher)
    }

}

extension CustomerInfoResponse.Transaction {

    init(
        purchaseDate: Date?,
        originalPurchaseDate: Date?,
        transactionIdentifier: String?,
        store: Store,
        isSandbox: Bool
    ) {
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.transactionIdentifier = transactionIdentifier
        self.store = store
        self.isSandbox = isSandbox
    }

    var asSubscription: CustomerInfoResponse.Subscription {
        return .init(purchaseDate: self.purchaseDate,
                     originalPurchaseDate: self.originalPurchaseDate,
                     store: self.store,
                     isSandbox: self.isSandbox)
    }

}

extension CustomerInfoResponse.Subscription {

    init(
        periodType: PeriodType = .defaultValue,
        purchaseDate: Date? = nil,
        originalPurchaseDate: Date? = nil,
        expiresDate: Date? = nil,
        store: Store = .defaultValue,
        isSandbox: Bool,
        unsubscribeDetectedAt: Date? = nil,
        billingIssuesDetectedAt: Date? = nil,
        ownershipType: PurchaseOwnershipType = .defaultValue
    ) {
        self.periodType = periodType
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.expiresDate = expiresDate
        self.store = store
        self.isSandbox = isSandbox
        self.unsubscribeDetectedAt = unsubscribeDetectedAt
        self.billingIssuesDetectedAt = billingIssuesDetectedAt
        self.ownershipType = ownershipType
    }

    var asTransaction: CustomerInfoResponse.Transaction {
        return .init(purchaseDate: self.purchaseDate,
                     originalPurchaseDate: self.originalPurchaseDate,
                     transactionIdentifier: nil,
                     store: self.store,
                     isSandbox: self.isSandbox)
    }

}

extension CustomerInfoResponse.Subscriber {

    var allTransactionsByProductId: [String: CustomerInfoResponse.Transaction] {
        return self.allPurchasesByProductId.mapValues { $0.asTransaction }
    }

    var allPurchasesByProductId: [String: CustomerInfoResponse.Subscription] {
        let subscriptions = self.subscriptions
        let latestNonSubscriptionTransactionsByProductId = self.nonSubscriptions
            .compactMapValues { $0.last }
            .mapValues { $0.asSubscription }

        return subscriptions + latestNonSubscriptionTransactionsByProductId
    }

}
