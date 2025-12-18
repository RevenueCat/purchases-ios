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
//  Created by Toni Rico on 5/6/25.

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

    struct PurchaseOption {
        // Only for non-subscriptions
        @IgnoreDecodeErrors<Price?>
        var basePrice: Price?

        // Only for subscriptions
        @IgnoreDecodeErrors<PricingPhase?>
        var base: PricingPhase?
        @IgnoreDecodeErrors<PricingPhase?>
        var trial: PricingPhase?
    }

    struct Product {
        let identifier: String
        let productType: String
        let title: String
        let description: String?
        let defaultPurchaseOptionId: String?
        let purchaseOptions: [String: PurchaseOption]
    }

    struct Package {
        let identifier: String
        let webCheckoutUrl: String
        let productDetails: Product
    }

    struct Offering {
        let identifier: String
        let description: String?
        let packages: [String: Package]
    }

    let offerings: [String: Offering]

}

extension WebProductsResponse.Offering: Codable, Equatable {}
extension WebProductsResponse.Package: Codable, Equatable {}
extension WebProductsResponse.Product: Codable, Equatable {}
extension WebProductsResponse.PurchaseOption: Codable, Equatable {}
extension WebProductsResponse.PricingPhase: Codable, Equatable {}
extension WebProductsResponse.Price: Codable, Equatable {}

extension WebProductsResponse: Codable, Equatable {}

extension WebProductsResponse: HTTPResponseBody {}
