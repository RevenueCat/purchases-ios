//
//  StoreKit2PromotionalOfferPurchaseOptionsAPI.swift
//  CustomEntitlementComputationSwiftAPITester
//
//  Created by Will Taylor on 12/4/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

var promoOfferPurchaseOptions: StoreKit2PromotionalOfferPurchaseOptions!
func checkAPI() {
    let offerID: String = promoOfferPurchaseOptions.offerID
    let compactJWS: String = promoOfferPurchaseOptions.compactJWS
}

func checkInit() {
    let options: StoreKit2PromotionalOfferPurchaseOptions = StoreKit2PromotionalOfferPurchaseOptions(
        offerID: "abc",
        compactJWS: "123"
    )
}
