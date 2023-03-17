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


/// This struct should have all the information we need from StoreKit  to create EntitlementInfo from a StoreKit 2 transaction.
/// Other fields from other places might be needed.
/// If not, then consider just having a constructor that creates EntitlementInfo from a Storekit.Transaction instead and using
/// a Factory pattern to store the logic in one place
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
struct PurchasedSK2Product {
    let productIdentifier: String
    let expirationDate: Date?
    let periodType: PeriodType

    init(from transaction: StoreKit.Transaction) {
        self.productIdentifier = transaction.productID
        self.expirationDate = transaction.expirationDate
        if let offerType = transaction.offerType {
            switch offerType {
            case .code, .promotional:
                self.periodType = .intro
            case .introductory:
                // note: this isn't necessarily accurate, but there's no field in SK2 to
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
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
struct PurchasedProductsManager {

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        var purchasedProductIdentifiers: [PurchasedSK2Product] = []

        for await transaction in StoreKit.Transaction.all {
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
