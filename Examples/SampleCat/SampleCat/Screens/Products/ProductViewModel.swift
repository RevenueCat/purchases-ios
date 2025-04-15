import RevenueCat
import SwiftUI

struct ProductViewModel: Identifiable, Hashable {
    let id: String
    let title: String?
    let icon: String
    let description: String
    let storeProduct: StoreProduct?
    
    static func == (lhs: ProductViewModel, rhs: ProductViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
