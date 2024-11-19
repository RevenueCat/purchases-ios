//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasedSK2Product.swift
//
//  Created by Nacho Soto on 3/21/23.

import Foundation
import StoreKit

/// Contains all information from a StoreKit 2 transaction necessary to create an ``EntitlementInfo``.
struct PurchasedSK2Product {

    let productIdentifier: String
    let subscription: CustomerInfoResponse.Subscription
    let entitlement: CustomerInfoResponse.Entitlement

}

extension PurchasedSK2Product: Equatable {}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchasedSK2Product {

    init(
        from transaction: StoreKit.Transaction,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) {
        let expiration = transaction.expirationDate

        self.productIdentifier = transaction.productID
        self.subscription = .init(
            periodType: transaction.offerType?.periodType ?? .normal,
            purchaseDate: transaction.purchaseDate,
            originalPurchaseDate: transaction.purchaseDate,
            expiresDate: transaction.expirationDate,
            store: .appStore,
            isSandbox: sandboxEnvironmentDetector.isSandbox,
            ownershipType: transaction.ownershipType.type
        )
        self.entitlement = .init(
            expiresDate: expiration,
            productIdentifier: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            rawData: (try? transaction.jsonRepresentation.asJSONDictionary()) ?? [:]
        )
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension StoreKit.Transaction.OfferType {

    var periodType: PeriodType {
        switch self {
        case .code, .promotional:
            return .intro
        case .introductory:
            // note: this isn't entirely accurate, but there's no field in SK2 to
            // tell us whether this is a free trial after all, so it's a best guess.
            // since free trials are much more common than intro pricing, we're going with
            // trial
            return .trial
        default:
            return .normal
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension StoreKit.Transaction.OwnershipType {

    var type: PurchaseOwnershipType {
        switch self {
        case .familyShared:
            return  .familyShared
        default:
            return .purchased
        }
    }

}
