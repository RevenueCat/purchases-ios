//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebProductsResponse.swift
//
//  Created by Antonio Pallares on 23/7/25.

import Foundation

struct WebProductsResponse {

    struct Price {
        let amountMicros: Int64
        // This will be a 3-letter currency code
        let currency: String
    }

    struct PricingPhase {
        let periodDuration: String?
        let price: Price?
        let cycleCount: Int
    }

    enum ProductType: String {
        case subscription
        case consumable
        case nonConsumable = "non_consumable"
        case unknown
    }

    struct PurchaseOption {
        // Only for non-subscriptions
        @IgnoreDecodeErrors<Price?>
        var basePrice: Price?

        // Only for subscriptions
        @IgnoreDecodeErrors<PricingPhase?>
        var base: PricingPhase?
        @IgnoreDecodeErrors<PricingPhase?>
        var trial: PricingPhase?
        @IgnoreDecodeErrors<PricingPhase?>
        var introPrice: PricingPhase?
    }

    struct Product {
        let identifier: String
        let productType: ProductType
        let title: String
        let description: String?
        let defaultPurchaseOptionId: String?
        let purchaseOptions: [String: PurchaseOption]
    }

    let productDetails: [Product]

}

extension WebProductsResponse.Product: Codable, Equatable {}
extension WebProductsResponse.PurchaseOption: Codable, Equatable {}
extension WebProductsResponse.PricingPhase: Codable, Equatable {}
extension WebProductsResponse.Price: Codable, Equatable {}

extension WebProductsResponse: Codable, Equatable {}

extension WebProductsResponse: HTTPResponseBody {}

extension WebProductsResponse.ProductType: Codable, Equatable {

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = WebProductsResponse.ProductType(rawValue: rawValue) ?? .unknown
    }
}
