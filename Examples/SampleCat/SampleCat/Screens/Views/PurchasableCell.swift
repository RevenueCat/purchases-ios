import SwiftUI

enum PurchasableCellState {
    case readyToPurchase
    case purchasing
    case purchased
    case cannotPurchase
    case purchasingOtherProduct
}

struct PurchasableCell: View {
    @Environment(\.colorScheme) private var scheme
    let purchasable: any PurchasableViewModel
    @State private var isPurchasing = false
    @Environment(UserViewModel.self) private var userViewModel

    var purchaseButtonTitle: LocalizedStringKey {
        switch state {
        case .readyToPurchase, .cannotPurchase, .purchasingOtherProduct: "Purchase"
        case .purchasing: "Purchasing..."
        case .purchased: "Purchased"
        }
    }

    var state: PurchasableCellState {
        if purchasable.isPurchased() {
            return .purchased
        }

        if isPurchasing {
            return .purchasing
        } else if userViewModel.isPurchasing {
            return .purchasingOtherProduct
        }

        return .readyToPurchase
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(purchasable.title ?? "")
                Spacer()
                Image(systemName: purchasable.icon)
                    .foregroundStyle(purchasable.color)
            }
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
            Text(purchasable.id)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(purchasable.description)
                .font(.caption)

            Button(action: {
                Task {
                    isPurchasing = true
                    await purchasable.purchase()
                    isPurchasing = false
                }
            }) {
                Group {
                    if state == .purchased {
                        Label(purchaseButtonTitle, systemImage: "checkmark.circle.fill")
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

            if purchasable.purchasable == nil {
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
