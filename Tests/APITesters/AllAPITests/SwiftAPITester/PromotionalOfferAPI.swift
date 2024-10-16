//
//  PromotionalOfferAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 4/18/22.
//

import Foundation
import RevenueCat
import StoreKit

var offer: PromotionalOffer!
func checkPromotionalOfferAPI() {
    let _: StoreProductDiscount = offer.discount
    let _: SK1ProductDiscount? = offer.discount.sk1Discount

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: SK2ProductDiscount? = offer.discount.sk2Discount
    }

    let signedData: PromotionalOffer.SignedData = offer.signedData

    let _: String = signedData.identifier
    let _: String = signedData.keyIdentifier
    let _: UUID = signedData.nonce
    let _: String = signedData.signature
    let _: Int = signedData.timestamp
}
