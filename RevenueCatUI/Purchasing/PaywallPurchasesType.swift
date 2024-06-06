//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPurchasesType.swift
//
//  Created by Nacho Soto on 9/12/23.

import RevenueCat

/// A simplified protocol for the subset of `PurchasesType` needed for `RevenueCatUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol PaywallPurchasesType: Sendable {

    @Sendable
    func purchase(package: Package) async throws -> PurchaseResultData

    @Sendable
    func restorePurchases() async throws -> CustomerInfo

    @Sendable
    func track(paywallEvent: PaywallEvent) async

}

extension Purchases: PaywallPurchasesType {}
