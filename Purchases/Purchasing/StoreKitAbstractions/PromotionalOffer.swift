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

internal struct PromotionalOffer {
    var identifier: String
    var keyIdentifier: String
    var nonce: UUID
    var signature: String
    var timestamp: Int

    @available(iOSApplicationExtension 12.2, *)
    var sk1SKPaymentDiscount: SKPaymentDiscount {
        return SKPaymentDiscount(identifier: self.identifier,
                                 keyIdentifier: self.keyIdentifier,
                                 nonce: self.nonce,
                                 signature: self.signature,
                                 timestamp: self.timestamp as NSNumber)
    }
}
