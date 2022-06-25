//
//  PromoOfferDetails.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/1/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct PromoOfferDetailsView: View {
    let package: Package
    
    @State private var eligibility: [StoreProductDiscount: PromotionalOffer?]? = nil
    
    private func price(_ discount: StoreProductDiscount) -> String {
        return "\(discount.price)"
    }
    
    private func paymentMode(_ discount: StoreProductDiscount) -> String {
        switch discount.paymentMode {
        case .payAsYouGo:
            return "pay as you go"
        case .payUpFront:
            return "pay up front"
        case .freeTrial:
            return "free trial"
        @unknown default:
            fatalError()
        }
    }
    
    private func period(_ discount: StoreProductDiscount) -> String {
        switch discount.subscriptionPeriod.unit {
        case .day:
            return "\(discount.subscriptionPeriod.value) day(s)"
        case .week:
            return "\(discount.subscriptionPeriod.value) weeks(s)"
        case .month:
            return "\(discount.subscriptionPeriod.value) month(s)"
        case .year:
            return "\(discount.subscriptionPeriod.value) year(s)"
        @unknown default:
            fatalError()
        }
    }
    
    func checkEligibility(storeProduct: StoreProduct) async {
        guard self.eligibility == nil else {
            return
        }
        
        await withTaskGroup(of: (StoreProductDiscount, PromotionalOffer?).self) { group in
            for discount in storeProduct.discounts {
                group.addTask {
                    do {
                        let promotionalOffer = try await Purchases.shared.promotionalOffer(forProductDiscount: discount, product: storeProduct)
                        return (discount, promotionalOffer)
                    } catch {
                        return (discount, nil)
                    }
                }
            }
            
            var temp = [StoreProductDiscount: PromotionalOffer]()
            
            for await pair in group {
                temp[pair.0] = pair.1
            }
            
            self.eligibility = temp
        }
    }
    
    func isEligible(_ discount: StoreProductDiscount) -> Bool? {
        return self.eligibility?[discount] != nil
    }
    
    var body: some View {
        List(package.storeProduct.discounts) { discount in
            VStack(alignment: .leading) {
                Text("**Ident:** \(discount.offerIdentifier ?? "-")")
                Text("**Price:** \(price(discount))")
                Text("**Payment:** \(paymentMode(discount))")
                Text("**Period:** \(period(discount))")
                
                if let isEligible = self.isEligible(discount) {
                    Text("**Eligible:** \(isEligible ? "yes" : "no")")
                } else {
                    Text("**Eligible:** <loading>")
                }
                
                Divider()
                
                if let promotionalOffer = self.eligibility?[discount] as? PromotionalOffer {
                    Text("Accept promo offer")
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                        .onTapGesture {
                            purchasePromo(promotionalOffer: promotionalOffer)
                        }
                }
            }
        }.task {
            await checkEligibility(storeProduct: package.storeProduct)
        }
    }
    
    func purchasePromo(promotionalOffer: PromotionalOffer) {
        Purchases.shared.purchase(package: self.package, promotionalOffer: promotionalOffer) { transaction, info, error, userCancelled in
            print("🚀 Info 💁‍♂️ - Transactions: \(transaction)")
            print("🚀 Info 💁‍♂️ - Info: \(info)")
            print("🚀 Info 💁‍♂️ - Error: \(error)")
            print("🚀 Info 💁‍♂️ - User Cancelled: \(userCancelled)")
        }
    }
}
