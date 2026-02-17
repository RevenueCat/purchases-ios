//
//  PurchaseManager.swift
//  RCTTester
//

import Foundation
import RevenueCat
import RevenueCatUI

/// Result type for purchase operations initiated outside of paywalls.
enum PurchaseOperationResult {
    case success(CustomerInfo)
    case userCancelled
    /// The transaction is pending external action (e.g., Ask to Buy approval, SCA authentication).
    /// The purchase may complete later when the pending action is resolved.
    case pending
    case failure(Error)
}

/// Error indicating a purchase is pending external action.
///
/// This is used to communicate deferred/pending transactions to RevenueCatUI's paywall,
/// which expects an error for non-success, non-cancelled results.
enum PurchasePendingError: LocalizedError {
    case transactionPending

    var errorDescription: String? {
        "The purchase is pending approval (e.g., Ask to Buy). It may complete later."
    }
}

/// Result type for restore operations.
///
/// - Note: A successful restore (no error thrown) does not guarantee that entitlements were restored.
///   The `purchasesRecovered` field indicates whether any purchases (active subscriptions or
///   non-subscriptions) were found and synced. Always check `customerInfo.entitlements` to verify
///   active entitlements.
struct RestoreOperationResult {
    let customerInfo: CustomerInfo

    /// `true` if the restore found any purchases (active subscriptions or non-subscriptions).
    /// `false` if the restore completed successfully but no purchases were found.
    ///
    /// - Important: This does NOT mean entitlements are active. Always verify
    ///   `customerInfo.entitlements.active` for entitlement status.
    let purchasesRecovered: Bool
}

/// Protocol that abstracts how the app interacts with the RevenueCat SDK for purchases.
///
/// The app uses this protocol agnostically without knowing the underlying integration mode.
@MainActor
protocol PurchaseManager: AnyObject {

    // MARK: - Paywall Integration

    /// Returns the `MyAppPurchaseLogic` to be passed to paywall modifiers.
    ///
    /// - Returns `nil` when `purchasesAreCompletedBy == .revenueCat`, meaning paywalls
    ///   use RevenueCat's built-in purchase handling.
    /// - Returns a configured `MyAppPurchaseLogic` when `purchasesAreCompletedBy == .myApp`,
    ///   allowing paywalls to delegate purchases to this manager.
    var myAppPurchaseLogic: MyAppPurchaseLogic? { get }

    // MARK: - Direct Purchase Operations

    /// Purchases a package using `Purchases.shared.purchase(package:)`.
    ///
    /// Unlike `purchase(product:)`, this includes offering/package context, which means
    /// RevenueCat analytics will associate the purchase with a specific offering.
    ///
    /// - Note: Only meaningful when purchases go through RevenueCat APIs.
    ///   For StoreKit-direct observer modes, this delegates to `purchase(product:)`.
    /// - Parameter package: The package to purchase.
    /// - Returns: The result of the purchase operation.
    func purchase(package: Package) async -> PurchaseOperationResult

    /// Purchases a product directly.
    ///
    /// When purchases go through RevenueCat, this calls `Purchases.shared.purchase(product:)`.
    /// When purchases go through StoreKit directly, this uses the underlying StoreKit API.
    ///
    /// - Parameter product: The store product to purchase.
    /// - Returns: The result of the purchase operation.
    func purchase(product: StoreProduct) async -> PurchaseOperationResult

    // MARK: - Restore Operations

    /// Restores previously completed purchases.
    ///
    /// Each implementation restores purchases using the appropriate mechanism for its integration mode:
    /// - RevenueCat mode and Observer mode through RevenueCat APIs: Use `Purchases.shared.restorePurchases()`
    /// - Observer mode (SK1): Uses `SKPaymentQueue.restoreCompletedTransactions()`
    /// - Observer mode (SK2): Uses `AppStore.sync()`
    ///
    /// - Returns: The result of the restore operation.
    /// - Throws: An error if the restore operation fails.
    /// - Warning: A successful restore does not imply that the user has any entitlements.
    ///   Always verify `customerInfo.entitlements.active` to confirm entitlement status.
    func restorePurchases() async throws -> RestoreOperationResult
}

// MARK: - Type Eraser

/// Type-erased wrapper for `PurchaseManager` to allow storing different implementations.
@MainActor
final class AnyPurchaseManager: PurchaseManager {

    private let wrapped: any PurchaseManager

    init<T: PurchaseManager>(_ manager: T) {
        self.wrapped = manager
    }

    var myAppPurchaseLogic: MyAppPurchaseLogic? {
        wrapped.myAppPurchaseLogic
    }

    func purchase(package: Package) async -> PurchaseOperationResult {
        await wrapped.purchase(package: package)
    }

    func purchase(product: StoreProduct) async -> PurchaseOperationResult {
        await wrapped.purchase(product: product)
    }

    func restorePurchases() async throws -> RestoreOperationResult {
        try await wrapped.restorePurchases()
    }
}

// MARK: - Factory

extension AnyPurchaseManager {

    /// Creates the appropriate `PurchaseManager` implementation based on the SDK configuration.
    ///
    /// - Parameter configuration: The current SDK configuration.
    /// - Returns: A `PurchaseManager` configured for the specified integration mode.
    static func create(for configuration: SDKConfiguration) -> AnyPurchaseManager {
        switch configuration.purchasesAreCompletedBy {
        case .revenueCat:
            return AnyPurchaseManager(RevenueCatPurchaseManager())

        case .myApp:
            switch configuration.purchaseLogic {
            case .throughRevenueCat:
                return AnyPurchaseManager(ThroughRevenueCatPurchaseManager())

            case .usingStoreKitDirectly:
                switch configuration.storeKitVersion {
                case .storeKit1:
                    return AnyPurchaseManager(StoreKit1PurchaseManager())
                case .storeKit2:
                    return AnyPurchaseManager(StoreKit2PurchaseManager())
                }
            }
        }
    }
}
