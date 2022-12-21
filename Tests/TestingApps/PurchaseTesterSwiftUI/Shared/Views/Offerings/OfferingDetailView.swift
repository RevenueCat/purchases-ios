//
//  OfferingDetailView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/1/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct OfferingDetailView: View {

    let offering: RevenueCat.Offering
    @State var isPurchasing = false
    
    var body: some View {
        VStack(alignment: .leading) {
            List(offering.availablePackages) { package in
                Section {
                    PackageItem(package: package, isPurchasing: self.$isPurchasing)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle(offering.serverDescription)
    }
    
    struct PackageItem: View {

        let package: RevenueCat.Package
        @Binding var isPurchasing: Bool

        @EnvironmentObject private var observerModeManager: ObserverModeManager
        @State private var isEligible: Bool? = nil
        
        func checkIntroEligibility() async {
            guard self.isEligible == nil else {
                return
            }
            
            let productIdentifier = package.storeProduct.productIdentifier
            let results = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: [productIdentifier])

            self.isEligible = results[productIdentifier]?.status == .eligible
        }
        
        var body: some View {
            VStack(alignment: .center) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("**Title:** \(package.storeProduct.localizedTitle)")
                        Text("**Desc:** \(package.storeProduct.localizedDescription)")
                        Text("**Pkg Id:** \(package.identifier)")
                        Text("**Sub Group:** \(package.storeProduct.subscriptionGroupIdentifier ?? "-")")
                        Text("**Package type:** \(package.display)")

                        if let period = package.storeProduct.subscriptionPeriod {
                            Text("**\(period.debugDescription)**")
                        } else {
                            Text("**Sub Period:** -")
                        }
                        
                        if let isEligible = self.isEligible {
                            Text("**Intro Elig:** \(isEligible ? "yes" : "no")")
                        } else {
                            Text("**Intro Elig:** <loading>")
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(package.storeProduct.localizedPriceString)")
                    
                }
                
                Divider()

                self.button("Buy as Package") {
                    try await self.purchaseAsPackage()
                }

                Divider()

                self.button("Buy as Product") {
                    try await self.purchaseAsProduct()
                }

                Divider()

                if self.observerModeManager.observerModeEnabled {
                    self.button("Buy directly from SK1 (w/o RevenueCat)") {
                        try await self.purchaseAsSK1Product()
                    }

                    self.button("Buy directly from SK2 (w/o RevenueCat)") {
                        try await self.purchaseAsSK2Product()
                    }

                    Divider()
                }
                    
                NavigationLink(destination: PromoOfferDetailsView(package: package)) {
                    Text("View Promo Offers")
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                }
            }
            .disabled(self.isPurchasing)
            .task {
                await self.checkIntroEligibility()
            }
        }
        
        private func purchaseAsPackage() async throws {
            self.isPurchasing = true

            let result = try await Purchases.shared.purchase(package: self.package)
            self.completedPurchase(result)
        }
        
        private func purchaseAsProduct() async throws {
            self.isPurchasing = true

            let result = try await Purchases.shared.purchase(product: self.package.storeProduct)
            self.completedPurchase(result)
        }

        private func purchaseAsSK1Product() async throws {
            self.isPurchasing = true
            try await self.observerModeManager.purchaseAsSK1Product(self.package.storeProduct)
            self.isPurchasing = false
        }

        private func purchaseAsSK2Product() async throws {
            self.isPurchasing = true
            try await self.observerModeManager.purchaseAsSK2Product(self.package.storeProduct)
            self.isPurchasing = false
        }

        private func completedPurchase(_ data: PurchaseResultData) {
            print("🚀 Info 💁‍♂️ - Transaction: \(data.transaction?.description ?? "")")
            print("🚀 Info 💁‍♂️ - Info: \(data.customerInfo)")
            print("🚀 Info 💁‍♂️ - User Cancelled: \(data.userCancelled)")

            self.isPurchasing = false
        }

        private func button(_ title: String, action: @escaping () async throws -> Void) -> some View {
            Button(title) {
                Task<Void, Never> {
                    do {
                        try await action()
                    } catch {
                        print("🚀 Error: \(error)")
                    }
                }
            }
            .foregroundColor(.blue)
            .padding(.vertical, 10)
        }
    }
}
