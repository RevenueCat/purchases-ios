//
//  MockSKProductDiscount.swift
//  Purchases
//
//  Created by Joshua Liebowitz on 7/6/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@available(iOS 11.2, *)
class MockSKProductDiscount: SKProductDiscount {

    private var privateIdentifier: String?
    public override var identifier: String? {
        get {
            return privateIdentifier
        }
        set {
            privateIdentifier = newValue
        }
    }

    private var privatePaymentMode: SKProductDiscount.PaymentMode
    public override var paymentMode: SKProductDiscount.PaymentMode {
        get {
            return privatePaymentMode
        }
        set {
            privatePaymentMode = newValue
        }
    }

    private var privatePrice: NSDecimalNumber
    public override var price: NSDecimalNumber {
        get {
            return privatePrice
        }
        set {
            privatePrice = newValue
        }
    }

    init(identifier: String? = "offerid", paymentMode: SKProductDiscount.PaymentMode, price: NSDecimalNumber) {
        self.privateIdentifier = identifier
        self.privatePaymentMode = paymentMode
        self.privatePrice    = price
    }

}
