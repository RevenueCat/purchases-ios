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
    
    var body: some View {
        VStack(alignment: .leading) {
            List(offering.availablePackages) { package in
                Section {
                    PackageItem(package: package)
                }
            }
        }.navigationTitle(offering.serverDescription)
    }
    
    struct PackageItem: View {
        let package: RevenueCat.Package
        
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

                        if let period = package.storeProduct.sk1Product?.subscriptionPeriod?.unit.rawValue {
                            Text("**Sub Period:** \(period)")
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
                
                Text("Buy as Package")
                    .foregroundColor(.blue)
                    .padding(.vertical, 10)
                    .onTapGesture {
                        Task<Void, Never> {
                            await self.purchaseAsPackage()
                        }
                    }
                
                Divider()
                
                Text("Buy as Product")
                    .foregroundColor(.blue)
                    .padding(.vertical, 10)
                    .onTapGesture {
                        Task<Void, Never> {
                            await self.purchaseAsProduct()
                        }
                    }

                Divider()
                    
                NavigationLink(destination: PromoOfferDetailsView(package: package)) {
                    Text("View Promo Offers")
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                }


            }.task {
                await self.checkIntroEligibility()
            }
        }
        
        private func purchaseAsPackage() async {
            do {
                let result = try await Purchases.shared.purchase(package: self.package)
                self.completedPurchase(result)
            } catch {
                print("🚀 Failed purchase: 💁‍♂️ - Error: \(error)")
            }
        }
        
        private func purchaseAsProduct() async {
            do {
                let result = try await Purchases.shared.purchase(product: self.package.storeProduct)
                self.completedPurchase(result)
            } catch {
                print("🚀 Purchase failed: 💁‍♂️ - Error: \(error)")
            }
        }

        private func completedPurchase(_ data: PurchaseResultData) {
            print("🚀 Info 💁‍♂️ - Transaction: \(data.transaction?.description ?? "")")
            print("🚀 Info 💁‍♂️ - Info: \(data.customerInfo)")
            print("🚀 Info 💁‍♂️ - User Cancelled: \(data.userCancelled)")
        }
    }
}
