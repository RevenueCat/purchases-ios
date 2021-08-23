//
//  PromotionalOffer.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/2/21.
//  Copyright © 2021 Purchases. All rights reserved.
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

    required public init(offerIdentifier: String?, price: NSDecimalNumber, paymentMode: ProductInfo.PaymentMode) {
        self.offerIdentifier = offerIdentifier
        self.price = price
        self.paymentMode = paymentMode
    }

}
