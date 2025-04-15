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
    @State private var isLoading = false
    @State private var presentedProduct: ProductViewModel?
    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-products",
                                    title: "Products",
                                    description: "Products are the individual in-app purchases and subscriptions you set up on the App Store.")
            VStack {
                ForEach(products) { product in
                    Button {
                        presentedProduct = product
                    } label: {
                        ProductCell(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .overlay {
                if isLoading {
                    Spinner()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ContentBackgroundView(color: .accent)
        }
        .sheet(item: $presentedProduct, content: { product in
            Text(product.title ?? product.id)
        })
        .task(getProductViewModels)
    }

    private func getProductViewModels() async {
        defer { isLoading = false }
        isLoading = true
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
                status: $0.status,
                title: $0.title,
                description: $0.description,
                storeProduct: storeProducts[$0.identifier]
            )
        }
    }
}

#Preview {
    ProductsView()
}


