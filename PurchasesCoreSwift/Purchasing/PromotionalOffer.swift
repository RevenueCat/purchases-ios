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
//  Created by Joshua Liebowitz on 7/2/21.
//

import Foundation
import StoreKit

class PromotionalOffer {

    let offerIdentifier: String?
    let price: NSDecimalNumber
    let paymentMode: ProductInfo.PaymentMode

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    convenience init(withProductDiscount productDiscount: SKProductDiscount) {
        let skPaymentMode = productDiscount.paymentMode
        let rcPaymentMode = ProductInfo.paymentMode(fromSKProductDiscountPaymentMode: skPaymentMode)
        self.init(offerIdentifier: productDiscount.identifier,
                  price: productDiscount.price,
                  paymentMode: rcPaymentMode)
    }

    // swiftlint:disable missing_docs
    public init(offerIdentifier: String?, price: NSDecimalNumber, paymentMode: ProductInfo.PaymentMode) {
    // swiftlint:enable missing_docs
        self.offerIdentifier = offerIdentifier
        self.price = price
        self.paymentMode = paymentMode
    }

}
