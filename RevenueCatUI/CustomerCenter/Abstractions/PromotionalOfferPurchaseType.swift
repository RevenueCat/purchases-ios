//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferPurchaseType.swift
//
//  Created by Cesar de la Vega on 16/7/24.

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol PromotionalOfferPurchaseType: Sendable {

    @Sendable
    func customerInfo() async throws -> CustomerInfo

    @Sendable
    func products(_ productIdentifiers: [String]) async -> [StoreProduct]

}
