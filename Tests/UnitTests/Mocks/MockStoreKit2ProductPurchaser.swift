//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2ProductPurchaser.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation
@testable import RevenueCat
import StoreKit

class MockStoreKit2ProductPurchaser: StoreKit2ProductPurchaserType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func purchase(
        product: any RevenueCat.PurchasableSK2Product,
        options: Set<StoreKit.Product.PurchaseOption>,
        storeKit2ConfirmInOptions: RevenueCat.StoreKit2ConfirmInOptions?
    ) async throws -> StoreKit.Product.PurchaseResult {
        return .pending
    }
}
