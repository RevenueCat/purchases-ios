//
//  MockPaymentDiscount.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 12/30/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
class MockPaymentDiscount: SKPaymentDiscount {

    var mockIdentifier: String

    init(mockIdentifier: String) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }
}
