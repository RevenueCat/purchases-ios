//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPuchasesOrchestrator.swift
//
//  Created by Nacho Soto on 7/27/23.

@testable import RevenueCat
import StoreKit

/// A simplified `PurchasesOrchestrator` used for simulating purchases
/// made from outside the SDK.
final class CustomPurchasesOrchestrator: NSObject {

    typealias SK1PurchaseCompletedResult = SK1Transaction

    private let finishTransactions: Bool
    private let paymentQueue: SKPaymentQueue

    private var sk1PurchaseCompleteCallbacksByProductID: [String: (SK1PurchaseCompletedResult) -> Void] = [:]

    init(finishTransactions: Bool) {
        self.finishTransactions = finishTransactions
        self.paymentQueue = .init()

        super.init()

        self.paymentQueue.add(self)
    }

    deinit {
        self.paymentQueue.remove(self)
    }

    func purchase(
        sk1Product product: SK1Product,
        completion: @escaping (SK1PurchaseCompletedResult) -> Void
    ) {
        let productIdentifier = product.productIdentifier
        assert(!productIdentifier.isEmpty)
        assert(self.sk1PurchaseCompleteCallbacksByProductID[productIdentifier] == nil)

        self.sk1PurchaseCompleteCallbacksByProductID[productIdentifier] = completion
        self.paymentQueue.add(.init(product: product))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @discardableResult
    func purchase(sk2Product product: SK2Product) async throws -> Product.PurchaseResult {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            if self.finishTransactions {
                await transaction.finish()
            }

            Logger.rcPurchaseSuccess(Message.purchasedSK2Product)

        case let .success(.unverified(transaction, error)):
            if self.finishTransactions {
                await transaction.finish()
            }

            throw error

        case .userCancelled: break
        case .pending: break
        @unknown default:
            fatalError()
        }

        return result
    }

}

extension CustomPurchasesOrchestrator {

    func purchase(sk1Product product: SK1Product) async throws -> SK1PurchaseCompletedResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.purchase(sk1Product: product) { transaction in
                if let error = transaction.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: transaction)
                }
            }
        }
    }

}

extension CustomPurchasesOrchestrator: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productIdentifier = transaction.payment.productIdentifier
            guard let completion = self.sk1PurchaseCompleteCallbacksByProductID[productIdentifier] else {
                continue
            }

            func finishAndReportCompletion() {
                if self.finishTransactions {
                    self.paymentQueue.finishTransaction(transaction)
                }

                self.sk1PurchaseCompleteCallbacksByProductID.removeValue(forKey: productIdentifier)

                completion(transaction)
            }

            switch transaction.transactionState {
            case .purchasing: break

            case .restored, .purchased:
                Logger.rcPurchaseSuccess(Message.purchasedSK1Product)
                finishAndReportCompletion()

            case .failed:
                Logger.rcPurchaseError(Message.errorPurchasingSK1Product)
                finishAndReportCompletion()

            case .deferred:
                fatalError("Not supported right now")

            @unknown default:
                break
            }
        }
    }

}

private enum Message: LogMessage {

    case purchasedSK1Product
    case errorPurchasingSK1Product
    case purchasedSK2Product

    var description: String {
        switch self {
        case .purchasedSK1Product:
            return "Successfully purchased SK1 product"
        case .errorPurchasingSK1Product:
            return "Error purchasing SK1 product"
        case .purchasedSK2Product:
            return "Successfully purchased SK2 product"
        }
    }

    var category: String {
        return "custom_purchases"
    }

}
