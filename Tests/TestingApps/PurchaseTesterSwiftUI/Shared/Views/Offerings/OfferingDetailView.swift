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
        @EnvironmentObject private var customerData: RevenueCatCustomerData
        @State private var eligibility: IntroEligibilityStatus? = nil
        
        @State private var error: Error?
        @State private var purchaseSucceeded: Bool = false
        @State private var purchaseUserCancelled: Bool = false

        private func checkIntroEligibility() async {
            guard self.eligibility == nil else { return }
            
            let productIdentifier = self.package.storeProduct.productIdentifier
            let results = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: [productIdentifier])

            self.eligibility = results[productIdentifier]?.status ?? .unknown
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
                        
                        if let eligibility = self.eligibility {
                            Text("**Intro Elig:** \(eligibility.description)")
                        } else {
                            Text("**Intro Elig:** <loading>")
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(package.storeProduct.localizedPriceString)")
                    
                }
                
                Divider()

                self.purchaseButton("Buy as Package") {
                    return await self.purchaseAsPackage()
                }

                Divider()

                self.purchaseButton("Buy as Product") {
                    return await self.purchaseAsProduct()
                }

                Divider()

                if self.observerModeManager.observerModeEnabled {
                    self.purchaseButton("Buy directly from SK1 (w/o RevenueCat)") {
                        return await self.purchaseAsSK1Product()
                    }

                    #if !os(visionOS)
                    self.purchaseButton("Buy directly from SK2 (w/o RevenueCat)") {
                        return await self.purchaseAsSK2Product()
                    }
                    #endif

                    Divider()
                }
                    
                NavigationLink(destination: PromoOfferDetailsView(package: package)) {
                    Text("View Promo Offers")
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                }
            }
            .disabled(self.isPurchasing)
            .alert(isPresented: self.$purchaseSucceeded) {
                Alert(title: Text("Purchased!"))
            }
            .alert(isPresented: self.$purchaseUserCancelled) {
                Alert(title: Text("User cancelled"))
            }
            .alert(
                isPresented: .init(get: { self.error != nil },
                                   set: { if $0 == false { self.error = nil } }),
                error: self.error.map(LocalizedAlertError.init),
                actions: { _ in
                    Button("OK") {
                        self.error = nil
                    }
                },
                message: { Text($0.subtitle) }
            )
            .task {
                await self.checkIntroEligibility()
            }
        }
        
        private func purchaseAsPackage() async -> PurchaseResult {
            self.isPurchasing = true
            defer { self.isPurchasing = false }

            let result: PurchaseResult
            do {
                let resultData: PurchaseResultData
                if let metadata = customerData.metadata {
                    #if ENABLE_TRANSACTION_METADATA
                    let params = PurchaseParams.Builder(package: package).with(metadata: metadata).build()
                    #else
                    let params = PurchaseParams.Builder(package: package).build()
                    print("⚠️ Warning - ENABLE_TRANSACTION_METADATA feature flag is not enabled")
                    print("⚠️ Warning - Metadata will not be sent with the purchase")
                    #endif
                    resultData = try await Purchases.shared.purchase(params)
                } else {
                    resultData = try await Purchases.shared.purchase(package: self.package)
                }

                self.completedPurchase(resultData)
                if resultData.userCancelled {
                    result = .userCancelled
                } else {
                    result = .success
                }
            } catch {
                result = .failure(error)
            }

            return result
        }
        
        private func purchaseAsProduct() async -> PurchaseResult {
            self.isPurchasing = true
            defer { self.isPurchasing = false }

            let result: PurchaseResult
            do {
                let resultData: PurchaseResultData
                if let metadata = customerData.metadata {
                    #if ENABLE_TRANSACTION_METADATA
                    let params = PurchaseParams.Builder(package: package).with(metadata: metadata).build()
                    #else
                    let params = PurchaseParams.Builder(package: package).build()
                    print("⚠️ Warning - ENABLE_TRANSACTION_METADATA feature flag is not enabled")
                    print("⚠️ Warning - Metadata will not be sent with the purchase")
                    #endif
                    resultData = try await Purchases.shared.purchase(params)
                } else {
                    resultData = try await Purchases.shared.purchase(product: self.package.storeProduct)
                }

                self.completedPurchase(resultData)
                if resultData.userCancelled {
                    result = .userCancelled
                } else {
                    result = .success
                }
            } catch {
                result = .failure(error)
            }

            return result
        }

        private func purchaseAsSK1Product() async -> PurchaseResult {
            self.isPurchasing = true
            defer { self.isPurchasing = false }

            return await self.observerModeManager.purchaseAsSK1Product(self.package.storeProduct)
        }

        #if !os(visionOS)
        private func purchaseAsSK2Product() async -> PurchaseResult {
            self.isPurchasing = true
            defer { self.isPurchasing = false }

            return await self.observerModeManager.purchaseAsSK2Product(self.package.storeProduct)
        }
        #endif

        private func completedPurchase(_ data: PurchaseResultData) {
            print("🚀 Info 💁‍♂️ - Transaction: \(data.transaction?.description ?? "")")
            print("🚀 Info 💁‍♂️ - Info: \(data.customerInfo)")
            print("🚀 Info 💁‍♂️ - User Cancelled: \(data.userCancelled)")
        }

        private func purchaseButton(_ title: String, purchaseAction: @escaping () async -> PurchaseResult) -> some View {
            Button(title) {
                Task<Void, Never> {
                    let purchaseResult = await purchaseAction()
                    switch purchaseResult {
                    case .success:
                        self.purchaseSucceeded = true
                    case .userCancelled:
                        self.purchaseUserCancelled = true
                    case .failure(let error):
                        self.error = error
                        print("🚀 Error: \(error)")
                    }
                }
            }
            .foregroundColor(.blue)
            .padding(.vertical, 10)
        }
    }
}

enum PurchaseResult {
    case success
    case userCancelled
    case failure(Error)
}
