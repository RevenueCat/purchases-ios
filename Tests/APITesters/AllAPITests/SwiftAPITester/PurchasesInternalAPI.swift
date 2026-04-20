//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesInternalAPI.swift
//
//  Exercises `@_spi(Internal)` accessors on `Purchases` so that any breaking
//  change to their signatures is caught by the API tester targets.

import Foundation
@_spi(Internal) import RevenueCat

func checkPurchasesInternalAPI() {
    let _: (Purchases) -> String = { $0.apiKey }
}
