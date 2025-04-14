import RevenueCat
import SwiftUI

struct ProductViewModel: Identifiable {
    let id: String
    let title: String?
    let icon: String
    let description: String
    let storeProduct: StoreProduct?
}
