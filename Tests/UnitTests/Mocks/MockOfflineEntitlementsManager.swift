//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfflineEntitlementsManager.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation
@testable import RevenueCat

class MockOfflineEntitlementsManager: OfflineEntitlementsManager {

    var invokedUpdateProductsEntitlementsCacheIfStale = false
    var invokedUpdateProductsEntitlementsCacheIfStaleCount = 0
    var invokedUpdateProductsEntitlementsCacheIfStaleParameters: Bool?
    var invokedUpdateProductsEntitlementsCacheIfStaleParametersList = [Bool]()

    override func updateProductsEntitlementsCacheIfStale(
        isAppBackgrounded: Bool,
        completion: (@MainActor (Result<(), OfflineEntitlementsManager.Error>) -> Void)?
    ) {
        self.invokedUpdateProductsEntitlementsCacheIfStale = true
        self.invokedUpdateProductsEntitlementsCacheIfStaleCount += 1
        self.invokedUpdateProductsEntitlementsCacheIfStaleParameters = isAppBackgrounded
        self.invokedUpdateProductsEntitlementsCacheIfStaleParametersList.append(isAppBackgrounded)
    }

}
