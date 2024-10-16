//
//  PromotionalOfferAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 4/18/22.
//

import Foundation
import RevenueCat_CustomEntitlementComputation
import StoreKit

var offer: PromotionalOffer!
func checkPromotionalOfferAPI() {
    let discount: StoreProductDiscount = offer.discount
    let sk1Discount = offer.discount.sk1Discount
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2Discount = offer.discount.sk2Discount
        print(sk2Discount!)
    }

    let signedData = offer.signedData

    let _: String = signedData.identifier
    let _: String = signedData.keyIdentifier
    let _: UUID = signedData.nonce
    let _: String = signedData.signature
    let _: Int = signedData.timestamp

    print(discount, sk1Discount!)
}
