//
//  ObserverModeThroughRevenueCatPurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit

/// Purchase manager for observer mode with RevenueCat purchase methods.
///
/// In this mode:
/// - `purchasesAreCompletedBy` is set to `.myApp`
/// - `purchaseLogic` is set to `.throughRevenueCat`
/// - RevenueCat's `purchase()` is called, but transactions are NOT auto-finished
/// - After purchase, the app must manually finish the transaction
/// - Works the same for both StoreKit 1 and StoreKit 2 (transaction finishing differs)
@MainActor
final class ObserverModeThroughRevenueCatPurchaseManager: PurchaseManager {

    // MARK: - PurchaseManager

    /// Returns `MyAppPurchaseLogic` because paywalls need custom purchase handling.
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

    /// Purchases a package using RevenueCat's purchase method, then finishes the transaction.
    func purchase(package: Package) async -> PurchaseOperationResult {
        do {
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                return .userCancelled
            }

            // Finish the transaction manually since purchasesAreCompletedBy is .myApp
            if let transaction = result.transaction {
                await finishTransaction(transaction)
            }

            return .success(result.customerInfo)
        } catch {
            return .failure(error)
        }
    }

    /// Restores purchases. RevenueCat handles syncing with the backend.
    ///
    /// - Warning: A successful restore does not imply that the user has any entitlements.
    ///   Always verify `customerInfo.entitlements.active` to confirm entitlement status.
    private func restorePurchases() async throws -> RestoreOperationResult {
        let customerInfo = try await Purchases.shared.restorePurchases()

        // Check if any purchases were found (not whether entitlements are active)
        let hasActiveSubscriptions = !customerInfo.activeSubscriptions.isEmpty
        let hasNonSubscriptions = !customerInfo.nonSubscriptions.isEmpty

        return RestoreOperationResult(
            customerInfo: customerInfo,
            purchasesRecovered: hasActiveSubscriptions || hasNonSubscriptions
        )
    }

    // MARK: - Private

    /// Finishes a transaction depending on whether it's SK1 or SK2.
    private func finishTransaction(_ storeTransaction: StoreTransaction) async {
        if let sk2Transaction = storeTransaction.sk2Transaction {
            await sk2Transaction.finish()
            print("✅ Finished SK2 transaction: \(sk2Transaction.id)")
        } else if let sk1Transaction = storeTransaction.sk1Transaction {
            SKPaymentQueue.default().finishTransaction(sk1Transaction)
            print("✅ Finished SK1 transaction: \(sk1Transaction.transactionIdentifier ?? "unknown")")
        }
    }
}
