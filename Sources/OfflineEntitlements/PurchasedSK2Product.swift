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

    /// The product identifier from StoreKit of the purchased item, i.e. `com.revenuecat.annual`
    let productIdentifier: String

    /// The product's id.
    /// When no billing plan is present, or it is an upFront billing plan, it's just the
    /// product identifier,  i.e. `com.revenuecat.annual`. When a billing plan is present, it will
    /// contain the billing plan, i.e. `com.revenuecat.annual:monthly`.
    let id: String

    /// The billing plan, if a non-upFront one is present.
    let productPlanIdentifier: String?
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
        self.productPlanIdentifier = Self.productPlanIdentifier(from: transaction)
        self.id = CompoundProductIdentifier(
            productIdentifier: transaction.productID,
            productPlanIdentifier: self.productPlanIdentifier
        )?.compoundProductIdentifier ?? transaction.productID
        self.subscription = .init(
            periodType: transaction.offerType?.periodType ?? .normal,
            purchaseDate: transaction.purchaseDate,
            originalPurchaseDate: transaction.purchaseDate,
            expiresDate: transaction.expirationDate,
            store: .appStore,
            isSandbox: sandboxEnvironmentDetector.isSandbox,
            ownershipType: transaction.ownershipType.type,
            productPlanIdentifier: self.productPlanIdentifier
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

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension PurchasedSK2Product {
    static func productPlanIdentifier(from transaction: StoreKit.Transaction) -> String? {
        #if compiler(>=6.3.2)
        if #available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *),
           let skBillingPlanType = transaction.billingPlanType,
           let billingPlanType = BillingPlanType.from(storeKitBillingPlanType: skBillingPlanType) {

            return billingPlanType.compoundProductIDPlanComponent

        } else {
            return nil
        }
        #else
        return nil
        #endif
    }
}
