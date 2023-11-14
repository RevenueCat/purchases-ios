//
//  PurchasesOrchestrator.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 12/19/22.
//

import RevenueCat
import StoreKit

/// Used to purchase products directly and test with observer mode.
final class PurchasesOrchestrator: NSObject {

    typealias PurchaseCompletedResult = SK1Transaction

    private let paymentQueue: SKPaymentQueue

    private var purchaseCompleteCallbacksByProductID: [String: (PurchaseCompletedResult) -> Void] = [:]

    override init() {
        self.paymentQueue = .init()

        super.init()

        self.paymentQueue.add(self)
    }

    deinit {
        self.paymentQueue.remove(self)
    }

    func purchase(
        sk1Product product: SK1Product,
        completion: @escaping (PurchaseCompletedResult) -> Void
    ) {
        let productIdentifier = product.productIdentifier
        assert(!productIdentifier.isEmpty)
        assert(self.purchaseCompleteCallbacksByProductID[productIdentifier] == nil)

        self.purchaseCompleteCallbacksByProductID[productIdentifier] = completion
        self.paymentQueue.add(.init(product: product))
    }

    // Fix-me: inject @Environment(\.product) to fix this
    #if !os(visionOS)
    func purchase(sk2Product product: SK2Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()

            print("Successfully purchased SK2 product")
        case let .success(.unverified(transaction, error)):
            await transaction.finish()

            throw error
        case .userCancelled:
            return
        case .pending:
            return
        @unknown default:
            fatalError()
        }
    }
    #endif

}

extension PurchasesOrchestrator {

    func purchase(sk1Product product: SK1Product) async -> PurchaseCompletedResult {
        return await withCheckedContinuation { continuation in
            self.purchase(sk1Product: product) { result in
                continuation.resume(returning: result)
            }
        }
    }

}

extension PurchasesOrchestrator: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productIdentifier = transaction.payment.productIdentifier
            guard let completion = self.purchaseCompleteCallbacksByProductID[productIdentifier] else {
                continue
            }

            func finishAndReportCompletion() {
                completion(transaction)
                self.paymentQueue.finishTransaction(transaction)
                self.purchaseCompleteCallbacksByProductID.removeValue(forKey: productIdentifier)
            }

            switch transaction.transactionState {
            case .purchasing: break

            case .restored, .purchased:
                print("Successfully purchased SK1 product")
                finishAndReportCompletion()

            case .failed:
                print("Error purchasing SK1 product")
                finishAndReportCompletion()

            case .deferred:
                fatalError("Not supported right now")

            @unknown default:
                break
            }
        }
    }

}
