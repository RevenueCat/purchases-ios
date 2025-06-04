import Foundation
import RevenueCat

struct PackageViewModel: PurchasableViewModel {
    let id: String
    let status: PurchasesDiagnostics.ProductStatus
    let title: String?
    let description: String
    let purchasable: Package?
    let isPurchased: () -> Bool
    let purchase: () async -> Void
}
