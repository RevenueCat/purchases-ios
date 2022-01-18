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
g
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
}
