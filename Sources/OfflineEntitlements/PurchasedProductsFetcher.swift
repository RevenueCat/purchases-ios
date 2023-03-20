//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasedProductsFetcher.swift
//
//  Created by Andrés Boedo on 3/17/23.

import Foundation
import StoreKit

/// This struct should have all the information we need from StoreKit
/// to create EntitlementInfo from a StoreKit 2 transaction.
/// Other fields from other places might be needed.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
struct PurchasedSK2Product {
    let productIdentifier: String
    let periodType: PeriodType
    let isActive: Bool
    let willRenew: Bool
    let latestPurchaseDate: Date?
    let originalPurchaseDate: Date?
    let expirationDate: Date?
    let store = Store.appStore
    let isSandbox: Bool
    let unsubscribeDetectedAt: Date?
    let billingIssueDetectedAt: Date?
    let ownershipType: PurchaseOwnershipType
    let verification: VerificationResult = .verified

    init(from transaction: StoreKit.Transaction,
         sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) {
        self.productIdentifier = transaction.productID
        self.expirationDate = transaction.expirationDate
        if let offerType = transaction.offerType {
            switch offerType {
            case .code, .promotional:
                self.periodType = .intro
            case .introductory:
                // note: this isn't entirely accurate, but there's no field in SK2 to
                // tell us whether this is a free trial after all, so it's a best guess.
                // since free trials are much more common than intro pricing, we're going with
                // trial
                self.periodType = .trial
            default:
                self.periodType = .normal
            }
        } else {
            self.periodType = .normal
        }

        self.isActive = expirationDate == nil || expirationDate! > Date() // todo: check what we usually do for non-subs
        self.willRenew = true // best guess, StoreKit.Transaction does not provide this info.
        self.latestPurchaseDate = transaction.purchaseDate
        self.originalPurchaseDate = transaction.originalPurchaseDate
        self.isSandbox = sandboxEnvironmentDetector.isSandbox
        self.unsubscribeDetectedAt = nil // best guess, StoreKit.Transaction does not provide this info.
        self.billingIssueDetectedAt = nil // best guess, StoreKit.Transaction does not provide this info.
        switch transaction.ownershipType {
        case .familyShared:
            self.ownershipType = .familyShared
        default:
            self.ownershipType = .purchased
        }
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
struct PurchasedProductsManager {

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        // todo: call force sync on sk2 before doing this
        var purchasedProductIdentifiers: [PurchasedSK2Product] = []

        // todo: filter out pending and unfinished transactions
        for await transaction in StoreKit.Transaction.currentEntitlements {
            switch transaction {
            case .unverified:
                print("unverified!")
                // todo: log
                //                throw ErrorUtils.storeProblemError(
                //                    withMessage: Strings.purchase.transaction_unverified(
                //                        productID: unverifiedTransaction.productID,
                //                        errorMessage: verificationError.localizedDescription
                //                    ).description,
                //                    error: verificationError
                //                )
            case let .verified(verifiedTransaction):
                purchasedProductIdentifiers.append(PurchasedSK2Product(from: verifiedTransaction))
            }
        }

        return purchasedProductIdentifiers
    }
}

//@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
//extension EntitlementInfo {
//    convenience init(from: PurchasedSK2Product, entitlementID: String, ... ) {
//        // set all the relevant fields here
//    }
//}
