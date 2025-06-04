import RevenueCat
import SwiftUI

enum PurchasableState {
    case readyToPurchase
    case purchasing
    case purchased
    case cannotPurchase
    case purchasingOtherProduct
}

protocol PurchasableViewModel: Hashable, Equatable, Identifiable {
    associatedtype UnderlyingPurchasable

    var id: String { get }
    var status: PurchasesDiagnostics.ProductStatus { get }
    var title: String? { get }
    var description: String { get }
    var purchasable: UnderlyingPurchasable? { get }
    var isPurchased: () -> Bool { get }
    var purchase: () async -> Void { get }
}

extension PurchasableViewModel {
    var icon: String {
        status.icon
    }

    var color: Color {
        status.color
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
