//
//  StoreKit1PurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit

/// Purchase manager that makes purchases directly with StoreKit 1.
///
/// In this mode:
/// - `purchasesAreCompletedBy` is set to `.myApp`
/// - `purchaseLogic` is set to `.usingStoreKitDirectly`
/// - `storeKitVersion` is set to `.storeKit1`
/// - Purchases are made directly with SKPaymentQueue
/// - RevenueCat observes transactions and syncs entitlements
@MainActor
final class StoreKit1PurchaseManager: NSObject, PurchaseManager {

    // MARK: - Properties

    private let paymentQueue: SKPaymentQueue = .default()

    /// Completion handlers for in-flight purchases, keyed by product identifier.
    /// Using `nonisolated(unsafe)` to allow cleanup in `deinit`.
    nonisolated(unsafe) private var purchaseCompletionHandlers: [String: (Result<SK1PurchaseResult, Error>) -> Void] = [:]

    /// Completion handler for an in-flight restore operation.
    nonisolated(unsafe) private var restoreCompletionHandler: ((Error?) -> Void)?

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
        // Cancel any in-flight purchase completion handlers
        for (_, completion) in purchaseCompletionHandlers {
            completion(.failure(SK1PurchaseError.unknown))
        }
        purchaseCompletionHandlers.removeAll()

        // Cancel any in-flight restore completion handler
        restoreCompletionHandler?(SK1PurchaseError.unknown)
        restoreCompletionHandler = nil

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

    /// Purchases a product directly using StoreKit 1's `SKPaymentQueue`.
    func purchase(product: StoreProduct) async -> PurchaseOperationResult {
        guard let sk1Product = product.sk1Product else {
            return .failure(SK1PurchaseError.productNotFound(product.productIdentifier))
        }
        return await purchaseSK1ProductAndHandleResult(sk1Product)
    }

    /// Delegates to `purchase(product:)` since "package" is a RevenueCat concept
    /// and this manager purchases through StoreKit directly.
    func purchase(package: Package) async -> PurchaseOperationResult {
        await purchase(product: package.storeProduct)
    }

    /// Restores purchases using SK1's `restoreCompletedTransactions()`.
    ///
    /// RevenueCat (in observer mode) will observe the restored transactions and sync entitlements.
    ///
    /// - Warning: A successful restore does not imply that the user has any entitlements.
    ///   Always verify `customerInfo.entitlements.active` to confirm entitlement status.
    func restorePurchases() async throws -> RestoreOperationResult {
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

    private func purchaseSK1ProductAndHandleResult(_ sk1Product: SKProduct) async -> PurchaseOperationResult {
        let result: SK1PurchaseResult
        do {
            result = try await purchaseSK1Product(sk1Product)
        } catch {
            return .failure(error)
        }

        switch result.transactionState {
        case .failed:
            if let skError = result.error as? SKError,
               skError.code == .paymentCancelled || skError.code == .overlayCancelled {
                return .userCancelled
            }
            return .failure(result.error ?? SK1PurchaseError.unknown)

        case .deferred:
            return .pending

        case .purchased, .restored:
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                return .success(customerInfo)
            } catch {
                print("Warning: Purchase succeeded but couldn't fetch customer info: \(error)")
                if let cachedInfo = Purchases.shared.cachedCustomerInfo {
                    return .success(cachedInfo)
                }
                return .failure(error)
            }

        case .purchasing:
            return .failure(SK1PurchaseError.unknown)

        @unknown default:
            return .failure(SK1PurchaseError.unknown)
        }
    }

    private func purchaseSK1Product(_ product: SKProduct) async throws -> SK1PurchaseResult {
        return try await withCheckedThrowingContinuation { continuation in
            let productIdentifier = product.productIdentifier

            assert(purchaseCompletionHandlers[productIdentifier] == nil,
                   "Purchase already in progress for \(productIdentifier)")

            purchaseCompletionHandlers[productIdentifier] = { result in
                continuation.resume(with: result)
            }

            let payment = SKPayment(product: product)
            paymentQueue.add(payment)
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension StoreKit1PurchaseManager: SKPaymentTransactionObserver {

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
            completion(.success(SK1PurchaseResult(transaction: transaction)))

        @unknown default:
            purchaseCompletionHandlers.removeValue(forKey: productIdentifier)
            completion(.success(SK1PurchaseResult(transaction: transaction)))
        }
    }

    @MainActor
    private func finishAndComplete(
        _ transaction: SKPaymentTransaction,
        productIdentifier: String,
        completion: (Result<SK1PurchaseResult, Error>) -> Void
    ) {
        paymentQueue.finishTransaction(transaction)
        purchaseCompletionHandlers.removeValue(forKey: productIdentifier)
        completion(.success(SK1PurchaseResult(transaction: transaction)))
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
