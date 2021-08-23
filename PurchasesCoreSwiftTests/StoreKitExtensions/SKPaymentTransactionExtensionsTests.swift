//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SKPaymentTransactionExtensionsTests.swift
//
//  Created by Juanpe Catalán on 3/8/21.

import XCTest
import Nimble
import StoreKit
@testable import PurchasesCoreSwift

class SKPaymentTransactionExtensionsTests: XCTestCase {

    func testNilProductIdentifierIfPaymentIsMissing() {
        let transaction = SKPaymentTransaction()
        expect(transaction.productIdentifier).to(beNil())
    }
    
    func testNilProductIdentifierIfPaymentDoesNotHaveProductIdenfier() {
        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment()
        
        expect(transaction.productIdentifier).to(beNil())
    }
    
    func testProductIdentifierFromAnyTransaction() {
        let expectedProductIdentifier = "com.product.id1"
        let product = MockSKProduct(mockProductIdentifier: expectedProductIdentifier)
        let payment = SKPayment(product: product)
        let transaction = MockTransaction()
        transaction.mockPayment = payment
        
        expect(transaction.productIdentifier).to(equal(expectedProductIdentifier))
    }

}
