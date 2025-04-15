//
//  PackagesView.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 7/4/25.
//

import RevenueCat
import SwiftUI

struct ProductsView: View {
    @Environment(UserViewModel.self) private var userViewModel

    @State private var products: [ProductViewModel] = []

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                ConceptIntroductionView(imageName: "visual-products",
                                        title: "Products",
                                        description: "Products are the individual in-app purchases and subscriptions that you have set up on the App Store.")
                VStack {
                    ForEach(products) { product in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Image(systemName: product.icon)
                                Text(product.id)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(product.description)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background {
                ContentBackgroundView(color: .accent)
            }
            .navigationTitle("Products")
            .toolbar(removing: .title)
        }
        .task(getProductViewModels)
    }

    private func getProductViewModels() async {
        let report = await PurchasesDiagnostics.default.healthReport()
        let reportProducts = report.products
        let identifiers = reportProducts.map(\.identifier)
        let storeProducts = await Purchases.shared.products(identifiers)
            .reduce(into: [String: StoreProduct]()) { partialResult, storeProduct in
                partialResult[storeProduct.productIdentifier] = storeProduct
            }

        self.products = reportProducts.map {
            ProductViewModel(
                id: $0.identifier,
                title: $0.title,
                icon: $0.status.icon,
                description: $0.description,
                storeProduct: storeProducts[$0.identifier]
            )
        }
        print(report.status)
    }
}

#Preview {
    ProductsView()
}


