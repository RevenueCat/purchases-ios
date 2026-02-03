//
//  ObserverModeStoreKit2PurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit

/// Purchase manager for observer mode with direct StoreKit 2 purchases.
///
/// In this mode:
/// - `purchasesAreCompletedBy` is set to `.myApp`
/// - `purchaseLogic` is set to `.usingStoreKitDirectly`
/// - `storeKitVersion` is set to `.storeKit2`
/// - Purchases are made directly with StoreKit 2's Product.purchase()
/// - RevenueCat observes transactions and syncs entitlements
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class ObserverModeStoreKit2PurchaseManager: PurchaseManager {

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
        guard let sk2Product = package.storeProduct.sk2Product else {
            return .failure(SK2PurchaseError.productNotFound(package.storeProduct.productIdentifier))
        }

        // Make the purchase with SK2
        do {
            let result = try await sk2Product.purchase()

            // Notify RevenueCat about the purchase result.
            // This is required in observer mode with SK2 so RevenueCat can sync the transaction.
            _ = try await Purchases.shared.recordPurchase(result)

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Finish the transaction after RevenueCat has recorded it
                    await transaction.finish()
                    print("✅ SK2 purchase succeeded for \(sk2Product.id)")

                    // Get updated customer info
                    let customerInfo = try await Purchases.shared.customerInfo()
                    return .success(customerInfo)

                case .unverified(let transaction, let error):
                    // Transaction failed verification, but we still need to finish it
                    await transaction.finish()
                    print("❌ SK2 transaction unverified for \(sk2Product.id): \(error)")
                    return .failure(error)
                }

            case .userCancelled:
                print("⚠️ SK2 purchase cancelled by user for \(sk2Product.id)")
                return .userCancelled

            case .pending:
                // Transaction is pending external action (e.g., Ask to Buy approval)
                print("⏳ SK2 purchase pending for \(sk2Product.id)")
                return .pending

            @unknown default:
                return .failure(SK2PurchaseError.unknown)
            }
        } catch {
            print("❌ SK2 purchase failed for \(sk2Product.id): \(error)")
            return .failure(error)
        }
    }

    /// Restores purchases using SK2's `AppStore.sync()`.
    ///
    /// RevenueCat (in observer mode) will observe the synced transactions and update entitlements.
    ///
    /// - Warning: A successful restore does not imply that the user has any entitlements.
    ///   Always verify `customerInfo.entitlements.active` to confirm entitlement status.
    private func restorePurchases() async throws -> RestoreOperationResult {
        // Trigger SK2 sync - RevenueCat will observe the transactions
        try await AppStore.sync()

        // Fetch updated customer info after sync completes
        let customerInfo = try await Purchases.shared.customerInfo()

        // Check if any purchases were found (not whether entitlements are active)
        let hasActiveSubscriptions = !customerInfo.activeSubscriptions.isEmpty
        let hasNonSubscriptions = !customerInfo.nonSubscriptions.isEmpty

        return RestoreOperationResult(
            customerInfo: customerInfo,
            purchasesRecovered: hasActiveSubscriptions || hasNonSubscriptions
        )
    }
}

// MARK: - Errors

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum SK2PurchaseError: LocalizedError {
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
