//
//  ObserverModeStoreKit1PurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit

/// Purchase manager for observer mode with direct StoreKit 1 purchases.
///
/// In this mode:
/// - `purchasesAreCompletedBy` is set to `.myApp`
/// - `purchaseLogic` is set to `.usingStoreKitDirectly`
/// - `storeKitVersion` is set to `.storeKit1`
/// - Purchases are made directly with SKPaymentQueue
/// - RevenueCat observes transactions and syncs entitlements
@MainActor
final class ObserverModeStoreKit1PurchaseManager: NSObject, PurchaseManager {

    // MARK: - Properties

    private let paymentQueue: SKPaymentQueue = .default()
    private var purchaseCompletionHandlers: [String: (SK1PurchaseResult) -> Void] = [:]

    // MARK: - Types

    struct SK1PurchaseResult {
        let transaction: SKPaymentTransaction
        var transactionState: SKPaymentTransactionState { transaction.transactionState }
        var error: Error? { transaction.error }
    }

    // MARK: - Init

    override init() {
        super.init()
        self.paymentQueue.add(self)
    }

    deinit {
        self.paymentQueue.remove(self)
    }

    // MARK: - PurchaseManager

    var myAppPurchaseLogic: MyAppPurchaseLogic? {
        return MyAppPurchaseLogic(
            performPurchase: { [weak self] package in
                guard let self else { return (userCancelled: true, error: nil) }
                let result = await self.purchase(package: package)
                switch result {
                case .success:
                    return (userCancelled: false, error: nil)
                case .userCancelled:
                    return (userCancelled: true, error: nil)
                case .pending:
                    return (userCancelled: false, error: PurchasePendingError.transactionPending)
                case .failure(let error):
                    return (userCancelled: false, error: error)
                }
            },
            performRestore: { [weak self] in
                guard let self else { return (success: false, error: nil) }
                do {
                    let result = try await self.restorePurchases()
                    return (success: result.purchasesRecovered, error: nil)
                } catch {
                    return (success: false, error: error)
                }
            }
        )
    }

    func purchase(package: Package) async -> PurchaseOperationResult {
        guard let sk1Product = package.storeProduct.sk1Product else {
            return .failure(SK1PurchaseError.productNotFound(package.storeProduct.productIdentifier))
        }

        // Make the purchase with SK1
        let result = await purchaseSK1Product(sk1Product)

        // Handle the result based on transaction state
        switch result.transactionState {
        case .failed:
            if let skError = result.error as? SKError,
               skError.code == .paymentCancelled || skError.code == .overlayCancelled {
                return .userCancelled
            }
            return .failure(result.error ?? SK1PurchaseError.unknown)

        case .deferred:
            // Transaction requires external action (e.g., Ask to Buy approval)
            return .pending

        case .purchased, .restored:
            // Get updated customer info after purchase
            // RevenueCat should have observed the transaction and synced entitlements
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                return .success(customerInfo)
            } catch {
                // Purchase succeeded but couldn't get customer info
                print("Warning: Purchase succeeded but couldn't fetch customer info: \(error)")
                if let cachedInfo = Purchases.shared.cachedCustomerInfo {
                    return .success(cachedInfo)
                }
                return .failure(error)
            }

        case .purchasing:
            // This shouldn't happen as the completion is only called after purchasing
            return .failure(SK1PurchaseError.unknown)

        @unknown default:
            return .failure(SK1PurchaseError.unknown)
        }
    }

    /// Restores purchases using SK1's `restoreCompletedTransactions()`.
    ///
    /// RevenueCat (in observer mode) will observe the restored transactions and sync entitlements.
    ///
    /// - Warning: A successful restore does not imply that the user has any entitlements.
    ///   Always verify `customerInfo.entitlements.active` to confirm entitlement status.
    private func restorePurchases() async throws -> RestoreOperationResult {
        // Trigger SK1 restore - RevenueCat will observe the restored transactions
        try await restoreCompletedTransactionsSK1()

        // Fetch updated customer info after restore completes
        let customerInfo = try await Purchases.shared.customerInfo()

        // Check if any purchases were found (not whether entitlements are active)
        let hasActiveSubscriptions = !customerInfo.activeSubscriptions.isEmpty
        let hasNonSubscriptions = !customerInfo.nonSubscriptions.isEmpty

        return RestoreOperationResult(
            customerInfo: customerInfo,
            purchasesRecovered: hasActiveSubscriptions || hasNonSubscriptions
        )
    }

    private var restoreCompletionHandler: ((Error?) -> Void)?

    private func restoreCompletedTransactionsSK1() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            assert(restoreCompletionHandler == nil, "Restore already in progress")

            restoreCompletionHandler = { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            paymentQueue.restoreCompletedTransactions()
        }
    }

    // MARK: - Private SK1 Purchase

    private func purchaseSK1Product(_ product: SKProduct) async -> SK1PurchaseResult {
        return await withCheckedContinuation { continuation in
            let productIdentifier = product.productIdentifier

            assert(purchaseCompletionHandlers[productIdentifier] == nil,
                   "Purchase already in progress for \(productIdentifier)")

            purchaseCompletionHandlers[productIdentifier] = { result in
                continuation.resume(returning: result)
            }

            let payment = SKPayment(product: product)
            paymentQueue.add(payment)
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension ObserverModeStoreKit1PurchaseManager: SKPaymentTransactionObserver {

    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        Task { @MainActor in
            for transaction in transactions {
                handleTransaction(transaction)
            }
        }
    }

    @MainActor
    private func handleTransaction(_ transaction: SKPaymentTransaction) {
        let productIdentifier = transaction.payment.productIdentifier

        guard let completion = purchaseCompletionHandlers[productIdentifier] else {
            // This transaction wasn't initiated by us, possibly a restored or
            // externally initiated transaction. RevenueCat will handle it.
            return
        }

        switch transaction.transactionState {
        case .purchasing:
            // Still processing, do nothing
            break

        case .purchased, .restored:
            print("✅ SK1 purchase succeeded for \(productIdentifier)")
            finishAndComplete(transaction, productIdentifier: productIdentifier, completion: completion)

        case .failed:
            print("❌ SK1 purchase failed for \(productIdentifier): \(transaction.error?.localizedDescription ?? "unknown")")
            finishAndComplete(transaction, productIdentifier: productIdentifier, completion: completion)

        case .deferred:
            // For deferred transactions (e.g., Ask to Buy), complete with a deferred result
            print("⏳ SK1 purchase deferred for \(productIdentifier)")
            // Don't finish the transaction - it will be processed when approved
            purchaseCompletionHandlers.removeValue(forKey: productIdentifier)
            completion(SK1PurchaseResult(transaction: transaction))

        @unknown default:
            break
        }
    }

    @MainActor
    private func finishAndComplete(
        _ transaction: SKPaymentTransaction,
        productIdentifier: String,
        completion: (SK1PurchaseResult) -> Void
    ) {
        paymentQueue.finishTransaction(transaction)
        purchaseCompletionHandlers.removeValue(forKey: productIdentifier)
        completion(SK1PurchaseResult(transaction: transaction))
    }

    // MARK: - Restore Callbacks

    nonisolated func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Task { @MainActor in
            let completion = restoreCompletionHandler
            restoreCompletionHandler = nil
            completion?(nil)
        }
    }

    nonisolated func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Task { @MainActor in
            let completion = restoreCompletionHandler
            restoreCompletionHandler = nil
            completion?(error)
        }
    }
}

// MARK: - Errors

enum SK1PurchaseError: LocalizedError {
    case productNotFound(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound(let identifier):
            return "Product not found: \(identifier)"
        case .unknown:
            return "An unknown error occurred during the purchase"
        }
    }
}
