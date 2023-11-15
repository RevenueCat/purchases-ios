//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionFetcher.swift
//
//  Created by Nacho Soto on 5/24/23.

import Foundation
import StoreKit

protocol StoreKit2TransactionFetcherType: Sendable {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var receipt: StoreKit2Receipt { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var hasPendingConsumablePurchase: Bool { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: StoreTransaction? { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: StoreTransaction? { get async }

}

final class StoreKit2TransactionFetcher: StoreKit2TransactionFetcherType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .compactMap { $0.verifiedStoreTransaction }
                .extractValues()
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var hasPendingConsumablePurchase: Bool {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .compactMap { $0.verifiedTransaction }
                .map(\.productType)
                .map { StoreProduct.ProductType($0) }
                .contains {  $0.productCategory == .nonSubscription }
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: StoreTransaction? {
        get async {
            await StoreKit.Transaction.all
                .compactMap { $0.verifiedStoreTransaction }
                .filter { $0.sk2Transaction?.productType == .autoRenewable }
                .first { _ in true }
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: StoreTransaction? {
        get async {
            await StoreKit.Transaction.all
                .compactMap { $0.verifiedStoreTransaction }
                .first { _ in true }
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var receipt: StoreKit2Receipt {
        get async {
            async let transactions = verifiedTransactionsJWS
            async let statuses = subscriptionStatusBySubscriptionGroupId
            async let appTransaction = appTransaction

            return await .init(
                environment: .xcode,
                subscriptionStatus: statuses.map({ (key: String, value: [Product.SubscriptionInfo.Status]) in
                        .init(
                            subscriptionGroupId: key,
                            renewalInfoJWSTokens: value.map(\.renewalInfo.jwsRepresentation)
                        )
                }),
                transactions: transactions,
                bundleId: appTransaction?.bundleId ?? "",
                originalApplicationVersion: appTransaction?.originalApplicationVersion,
                originalPurchaseDate: appTransaction?.originalPurchaseDate
            )
        }
    }

}

// MARK: -

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKit.VerificationResult where SignedType == StoreKit.Transaction {

    var underlyingTransaction: StoreKit.Transaction {
        switch self {
        case let .unverified(transaction, _): return transaction
        case let .verified(transaction): return transaction
        }
    }

    var verifiedTransaction: StoreKit.Transaction? {
        switch self {
        case let .verified(transaction): return transaction
        case let .unverified(transaction, error):
            Logger.warn(Strings.storeKit.sk2_unverified_transaction(String(transaction.id), error))
            return nil
        }
    }

    fileprivate var verifiedStoreTransaction: StoreTransaction? {
        switch self {
        case let .verified(transaction): return StoreTransaction(sk2Transaction: transaction,
                                                                 jwsRepresentation: self.jwsRepresentation)
        case let .unverified(transaction, error):
            Logger.warn(Strings.storeKit.sk2_unverified_transaction(String(transaction.id), error))
            return nil
        }
    }

}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension StoreKit.VerificationResult where SignedType == StoreKit.AppTransaction {

    var verifiedAppTransaction: SK2AppTransaction? {
        switch self {
        case let .verified(transaction): return .init(appTransaction: transaction)
        case let .unverified(transaction, error):
            Logger.warn(
                Strings.storeKit.sk2_unverified_transaction(identifier: transaction.bundleID, error)
            )
            return nil
        }
    }

}

extension StoreKit2TransactionFetcher {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    private var verifiedTransactionsJWS: [String] {
        get async {
            return await StoreKit.Transaction.all
                .compactMap { $0.verifiedStoreTransaction?.jwsRepresentation }
                .extractValues()
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    private var subscriptionStatusBySubscriptionGroupId: [String: [Product.SubscriptionInfo.Status]] {
        get async {
            #if swift(>=5.9)
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return await StoreKit.Product.SubscriptionInfo.Status.all
                    .extractValues()
                    .reduce(into: [:]) {result, value in
                        result[value.groupID] = value.statuses
                    }
            }
            #endif

            // `StoreKit.Product.SubscriptionInfo.Status.all` is only available starting in iOS 17.0
            // For previous versions, we retrieve all the previously purchased transactions,
            // and fetch the subscription status only once per subscription group.
            var subscriptionGroups: Set<String> = []
            for await transaction in StoreKit.Transaction.all {
                if let verifiedTransaction = transaction.verifiedTransaction,
                   let subscriptionGroup = verifiedTransaction.subscriptionGroupID {
                    subscriptionGroups.insert(subscriptionGroup)
                }
            }

            let statusBySubscriptionGroup = await withTaskGroup(
                of: Optional<(String, [Product.SubscriptionInfo.Status])>.self,
                returning: [String: [Product.SubscriptionInfo.Status]].self) { taskGroup in

                for subscriptionGroup in subscriptionGroups {
                    taskGroup.addTask {
                        do {
                            let status = try await Product.SubscriptionInfo.status(for: subscriptionGroup)
                            return (subscriptionGroup, status)
                        } catch {
                            Logger.warn(
                                Strings.storeKit.sk2_error_fetching_subscription_status(subscriptionGroup, error)
                            )
                        }
                        return nil
                    }
                }

                return await taskGroup.reduce(
                    into: [String: [Product.SubscriptionInfo.Status]]()
                ) { result, value  in
                    if let value = value {
                        result[value.0] = value.1
                    }
                }
            }

            return statusBySubscriptionGroup
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    private var appTransaction: SK2AppTransaction? {
        get async {
            do {
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    let transaction = try await StoreKit.AppTransaction.shared
                    return transaction.verifiedAppTransaction
                } else {
                    Logger.warn(Strings.storeKit.sk2_app_transaction_unavailable)
                    return nil
                }
            } catch {
                Logger.warn(Strings.storeKit.sk2_error_fetching_app_transaction(error))
                return nil
            }
        }
    }

}
