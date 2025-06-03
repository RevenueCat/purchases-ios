import SwiftUI

enum ProductCellState {
    case readyToPurchase
    case purchasing
    case purchased
    case canNotPurchase
    case purchasingOtherProduct
}

struct ProductCell: View {
    @Environment(\.colorScheme) private var scheme
    let product: ProductViewModel
    @State private var isPurchasing = false
    @Environment(UserViewModel.self) private var userViewModel

    var state: ProductCellState {
        guard let storeProduct = product.storeProduct else {
            return .canNotPurchase
        }

        if userViewModel.customerInfo?.allPurchasedProductIdentifiers.contains(storeProduct.productIdentifier) == true {
            return .purchased
        }

        if isPurchasing {
            return .purchasing
        } else if userViewModel.isPurchasing {
            return .purchasingOtherProduct
        }

        return .readyToPurchase
    }

    var purchaseButtonTitle: LocalizedStringKey {
        switch state {
        case .readyToPurchase, .canNotPurchase, .purchasingOtherProduct: "Purchase"
        case .purchasing: "Purchasing..."
        case .purchased: "Purchased"
        }
    }

    var purchaseButtonIcon: String {
        "checkmark.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(product.title ?? "")
                Spacer()
                Image(systemName: product.icon)
                    .foregroundStyle(product.color)
            }
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
            Text(product.id)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(product.description)
                .font(.caption)

            Button(action: {
                guard let storeProduct = self.product.storeProduct else { return }

                Task {
                    isPurchasing = true
                    await userViewModel.purchase(storeProduct)
                    isPurchasing = false
                }
            }) {
                Group {
                    if state == .purchased {
                        Label(purchaseButtonTitle, systemImage: purchaseButtonIcon)
                    } else {
                        Text(purchaseButtonTitle)
                    }
                }
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .disabled(state != .readyToPurchase)

            if product.storeProduct == nil {
                Text("StoreKit did not return a product and no purchase can be made.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12))
    }
}
