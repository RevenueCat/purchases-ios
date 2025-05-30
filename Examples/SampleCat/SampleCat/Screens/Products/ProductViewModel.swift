import RevenueCat
import SwiftUI

struct ProductViewModel: Identifiable, Hashable {
    let id: String
    let status: PurchasesDiagnostics.ProductStatus
    let title: String?
    let description: String
    let storeProduct: StoreProduct?

    var icon: String {
        status.icon
    }

    var color: Color {
        status.color
    }

    static func == (lhs: ProductViewModel, rhs: ProductViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
