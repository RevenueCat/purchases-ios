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

/// A type that can fetch purchased products from StoreKit 2.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasedProductsFetcher {

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        var result: [PurchasedSK2Product] = []

        try await Self.forceSyncToEnsureAllTransactionsAreAccountedFor()

        for await transaction in StoreKit.Transaction.currentEntitlements {
            switch transaction {
            case let .unverified(unverifiedTransaction, verificationError):
                Logger.appleWarning(
                    Strings.offlineEntitlements.found_unverified_transactions_in_sk2(unverifiedTransaction,
                                                                                     verificationError)
                )
            case let .verified(verifiedTransaction):
                result.append(.init(from: verifiedTransaction))
            }
        }

        return result
    }

    private static func forceSyncToEnsureAllTransactionsAreAccountedFor() async throws {
        try await AppStore.sync()
    }

}
