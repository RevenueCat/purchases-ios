//
//  PaymentFactory.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 12/30/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCPaymentFactory) public class PaymentFactory: NSObject {
    @objc public var simulatesAskToBuyInSandbox = false
    
    @objc public func payment(product: SKProduct) -> SKMutablePayment {
        let payment = SKMutablePayment(product: product)
        payment.simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox
        return payment
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, macCatalyst 13.0, *)
    @objc public func payment(product: SKProduct, discount: SKPaymentDiscount) -> SKMutablePayment {
        let payment = self.payment(product: product)
        payment.paymentDiscount = discount
        return payment
    }
}
