//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPayment.swift
//
//  Created by Nacho Soto on 8/2/23.

import StoreKit

final class MockPayment: SKPayment {

    var mockProductIdentifier: String?

    override var productIdentifier: String {
        return self.mockProductIdentifier ?? ""
    }

}
