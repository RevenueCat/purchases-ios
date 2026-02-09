//
//  RevenueCatPurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI

/// Purchase manager for the standard RevenueCat integration mode.
///
/// In this mode:
/// - `purchasesAreCompletedBy` is set to `.revenueCat`
/// - RevenueCat handles all purchase and restore operations
/// - Paywalls don't need custom purchase logic
/// - Works the same for both StoreKit 1 and StoreKit 2
@MainActor
final class RevenueCatPurchaseManager: PurchaseManager {

    // MARK: - PurchaseManager

    /// Returns `nil` because RevenueCat handles purchases within paywalls.
    var myAppPurchaseLogic: MyAppPurchaseLogic? {
        return nil
    }

    /// Purchases a package using RevenueCat's built-in purchase method.
    func purchase(package: Package) async -> PurchaseOperationResult {
        do {
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                return .userCancelled
            }

            return .success(result.customerInfo)
        } catch {
            return .failure(error)
        }
    }

    /// Purchases a product using RevenueCat's `purchase(product:)` method.
    func purchase(product: StoreProduct) async -> PurchaseOperationResult {
        do {
            let result = try await Purchases.shared.purchase(product: product)

            if result.userCancelled {
                return .userCancelled
            }

            return .success(result.customerInfo)
        } catch {
            return .failure(error)
        }
    }

    /// Restores purchases using RevenueCat's built-in restore method.
    func restorePurchases() async throws -> RestoreOperationResult {
        let customerInfo = try await Purchases.shared.restorePurchases()

        let hasActiveSubscriptions = !customerInfo.activeSubscriptions.isEmpty
        let hasNonSubscriptions = !customerInfo.nonSubscriptions.isEmpty

        return RestoreOperationResult(
            customerInfo: customerInfo,
            purchasesRecovered: hasActiveSubscriptions || hasNonSubscriptions
        )
    }
}
