//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOffer.swift
//
//  Created by Josh Holtz on 1/18/22.

import Foundation
import StoreKit

/// The signed discount applied to a payment.
/// Contains the details of a promotional offer discount that you want to apply to a payment.
internal struct PromotionalOffer {
    var identifier: String
    var keyIdentifier: String
    var nonce: UUID
    var signature: String
    var timestamp: Int
}

extension PromotionalOffer {
    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    var sk1PromotionalOffer: SKPaymentDiscount {
        return SKPaymentDiscount(identifier: self.identifier,
                                 keyIdentifier: self.keyIdentifier,
                                 nonce: self.nonce,
                                 signature: self.signature,
                                 timestamp: self.timestamp as NSNumber)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var sk2PurchaseOption: Product.PurchaseOption {
        return .promotionalOffer(
            offerID: self.identifier,
            keyID: self.keyIdentifier,
            nonce: self.nonce,
            signature: self.signature.data(using: .utf8)!,
            timestamp: self.timestamp
        )
    }
}

/**
 * Enum of different possible states for intro price eligibility status.
 * * ``PromotionalOfferEligibility/ineligible`` The user is not eligible for a free trial or intro pricing for this
 * product.
 * * ``PromotionalOfferEligibility/eligible`` The user is eligible for a free trial or intro pricing for this product.
 */
@objc(RCPromotionalOfferEligibility) public enum PromotionalOfferEligibility: Int {

    /**
     The user is not eligible for promotional offer for this product.
     */
    case ineligible

    /**
     The user is eligible for a promotional offer for this product.
     */
    case eligible

}

extension PromotionalOfferEligibility: CaseIterable {}
