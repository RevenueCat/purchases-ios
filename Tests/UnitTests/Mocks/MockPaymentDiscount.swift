//
//  MockPaymentDiscount.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 12/30/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

class MockPaymentDiscount: SKPaymentDiscount {

    var mockIdentifier: String

    init(mockIdentifier: String) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }
}

extension MockPaymentDiscount: @unchecked Sendable {}
