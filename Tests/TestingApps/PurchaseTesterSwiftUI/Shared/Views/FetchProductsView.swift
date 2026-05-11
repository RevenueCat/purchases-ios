//
//  FetchProductsView.swift
//  Shared
//
//  Created by Will Taylor on 5/8/26.
//

import SwiftUI

import RevenueCat

struct FetchProductsView: View {

    @State private var productID = "com.revenuecat.sampleapp.monthly.12mocommitment"
    @State private var isLoading = false
    @State private var results: [StoreProduct]?

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                Form {
                    Section {
                        TextEditor(text: $productID)
                        Button {
                            Task(priority: .userInitiated) {
                                self.results = nil
                                self.isLoading = true
                                self.results = await Purchases.shared.products([productID])
                                self.isLoading = false
                            }
                        } label: {
                            Text("Fetch Products")
                        }
                    }

                    if let results {
                        Section {
                            if results.isEmpty {
                                Text("No products were returned.")
                            } else {
                                ForEach(results, id: \.productIdentifier) { storeProduct in
                                    StoreProductView(storeProduct)
                                }
                            }
                        } header: {
                            Text("Results")
                        }
                    }
                }
                .animation(.default, value: isLoading)
                .animation(.default, value: results)
                .navigationTitle(Text("Fetch Products"))
            }
        } else {
            Text("Use a newer iOS version.")
        }
    }

    private func StoreProductView(_ storeProduct: StoreProduct) -> some View {
        VStack(alignment: .leading) {
            Text(storeProduct.productIdentifier)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .padding(.bottom)

            if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
                if let installmentsInfo = storeProduct.installmentsInfo {
                    VStack(spacing: 10) {
                        LabeledContent {
                            Text(installmentsInfo.commitmentInstallmentsCount.description)
                        } label: {
                            Text("commitmentInstallmentsCount")
                        }
                        LabeledContent {
                            Text(installmentsInfo.commitmentTotalPeriod.debugDescription)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("commitmentTotalPeriod")
                        }
                        LabeledContent {
                            Text(installmentsInfo.commitmentTotalPrice.description)
                        } label: {
                            Text("commitmentTotalPrice")
                        }
                        LabeledContent {
                            Text(installmentsInfo.commitmentTotalDisplayPrice)
                        } label: {
                            Text("commitmentTotalDisplayPrice")
                        }
                        LabeledContent {
                            Text(installmentsInfo.installmentBillingPrice.description)
                        } label: {
                            Text("installmentBillingPrice")
                        }
                        LabeledContent {
                            Text(installmentsInfo.installmentBillingDisplayPrice)
                        } label: {
                            Text("installmentBillingDisplayPrice")
                        }

                    }
                    .padding()
                    .overlay {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 2)
                                .fill(Color.blue)
                        }
                    }
                } else {
                    Text("No installmentsInfo")
                }
            }
        }
    }
}
