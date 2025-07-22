//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTestStorePurchaseHandler.swift
//
//  Created by Antonio Pallares on 21/7/25.

import Foundation
@testable import RevenueCat

class MockTestStorePurchaseHandler: TestStorePurchaseHandlerType {

    #if TEST_STORE

    var stubbedPurchaseResult: Bool = true
    private var invokedPurchase: Bool = false
    private var invokedPurchaseProduct: TestStoreProduct? = nil

    @MainActor
    func purchase(product: TestStoreProduct, completion: @escaping (Bool) -> Void) throws {
        invokedPurchase = true
        invokedPurchaseProduct = product
        completion(self.stubbedPurchaseResult)
    }


    #endif // TEST_STORE
}
