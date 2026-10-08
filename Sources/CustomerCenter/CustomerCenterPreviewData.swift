//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewData.swift
//
//  Created by Monika on 6/10/2026.

import Foundation

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@_spi(Internal) public extension CustomerCenterConfigData {
    /// Decodes a captured preview response without configuring the Purchases singleton.
    static func preview(responseData: Data) throws -> CustomerCenterConfigData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return CustomerCenterConfigData(from: try decoder.decode(CustomerCenterConfigResponse.self, from: responseData))
    }
}

@_spi(Internal) public extension Offerings {
    /// Builds offerings using caller-supplied preview products, without fetching StoreKit products.
    static func preview(responseData: Data, products: [StoreProduct]) throws -> Offerings {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(OfferingsResponse.self, from: responseData)
        let productsByID = Dictionary(
            products.map { ($0.productIdentifier, $0) }, uniquingKeysWith: { first, _ in first }
        )
        let factory = OfferingsFactory(systemInfo: SystemInfo(
            platformInfo: nil, finishTransactions: false, apiKey: "preview",
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        ))
        let rawResponse = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let rawOfferings = rawResponse?["offerings"] as? [[String: Any]] ?? []
        let offerings = try response.offerings.compactMap { source in
            var offering = source
            if let raw = rawOfferings.first(where: { $0["identifier"] as? String == source.identifier }),
               let components = raw["paywall_components"], !(components is NSNull) {
                let data = try JSONSerialization.data(withJSONObject: components)
                let decoded = try? decoder.decode(PaywallComponentsData.self, from: data)
                offering.paywallComponents = decoded?.errorInfo == nil ? decoded : nil
                offering.hasPaywallComponents = offering.paywallComponents != nil
            }
            return factory.createOffering(from: productsByID, offering: offering, uiConfig: response.uiConfig)
        }
        return .preview(offerings: offerings, currentOfferingID: response.currentOfferingId)
    }
}
