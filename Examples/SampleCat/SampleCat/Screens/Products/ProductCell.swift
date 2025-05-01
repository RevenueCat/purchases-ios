//
//  ProductCell.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 15/4/25.
//

import SwiftUI

struct ProductCell: View {
    @Environment(\.colorScheme) private var scheme
    let product: ProductViewModel
    @State private var isPurchasing = false
    @Environment(UserViewModel.self) private var userViewModel

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
                Text(isPurchasing ? "Purchasing..." : "Purchase")
                    .font(.footnote)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            .disabled(product.storeProduct == nil || userViewModel.isPurchasing)
            .tint(.accentColor)

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
