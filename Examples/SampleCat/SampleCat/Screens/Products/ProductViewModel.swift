import Foundation
import RevenueCat

struct ProductViewModel: PurchasableViewModel {
    let id: String
    let status: PurchasesDiagnostics.ProductStatus
    let title: String?
    let description: String
    let purchasable: StoreProduct?
    let isPurchased: @MainActor @Sendable () -> Bool
    let purchase: @MainActor @Sendable () async -> Void
}
