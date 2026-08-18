//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2AlreadySubscribedDetector.swift
//
//  Created by Antonio Pallares on 27/2/26.

import StoreKit

/// Detects when a StoreKit 2 purchase returns an already-owned transaction rather than a new one.
///
/// SK2 returns `.success` with the existing transaction when a user tries to purchase a product
/// they already have (unlike SK1 which returns `ASDServerError.currentlySubscribed`). This helper
/// captures the pre-existing transaction ID before the purchase and compares it afterward.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
enum SK2AlreadySubscribedDetector {

    /// Returns the transaction ID of the product's latest transaction only when the product
    /// has already been fully processed for the current user.
    ///
    /// Returns `nil` (allowing the purchase through) when:
    /// - There is no existing verified transaction
    /// - The existing transaction is unfinished (receipt may not have been posted yet)
    /// - The current user doesn't own this product (e.g., after switching RC accounts)
    static func alreadyPurchasedTransactionID(
        for product: SK2Product,
        transactionFetcher: StoreKit2TransactionFetcherType,
        customerInfoManager: CustomerInfoManager,
        appUserID: String
    ) async -> String? {
        guard let latestResult = await product.latestTransaction,
              let verified = latestResult.verifiedTransaction else {
            return nil
        }

        let transactionID = String(verified.id)

        let unfinishedIDs = Set(
            await transactionFetcher.unfinishedVerifiedTransactions.map(\.transactionIdentifier)
        )
        if unfinishedIDs.contains(transactionID) {
            return nil
        }

        let cachedInfo = try? customerInfoManager.cachedCustomerInfo(appUserID: appUserID)
        let productOwnedByCurrentUser = cachedInfo?.activeSubscriptions.contains(product.id) == true
            || cachedInfo?.nonSubscriptions.contains(where: { $0.productIdentifier == product.id }) == true
        if !productOwnedByCurrentUser {
            return nil
        }

        return transactionID
    }

}
