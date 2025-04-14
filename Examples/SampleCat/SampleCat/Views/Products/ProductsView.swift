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
                VStack {
                    ForEach(products) { product in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: product.icon)
                            Text(product.id)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding()
            }
        }
        .task {
            let report = await PurchasesDiagnostics.default.healthReport()
            self.products = report.products
                .map {
                    ProductViewModel(
                        id: $0.identifier,
                        title: $0.title,
                        icon: $0.status.icon
                    )
                }
        }
        .navigationTitle("Products")
    }
}

#Preview {
    ProductsView()
}
