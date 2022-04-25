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
    let discount: StoreProductDiscount = offer.discount
    let sk1Discount = offer.discount.sk1Discount
    let sk2Discount = offer.discount.sk2Discount

    let signedData = offer.signedData

    let identifier: String = signedData.identifier
    let keyIdentifier: String = signedData.keyIdentifier
    let nonce: UUID = signedData.nonce
    let signature: String = signedData.signature
    let timestamp: Int = signedData.timestamp

    print(discount, sk1Discount!, sk2Discount!)
}
