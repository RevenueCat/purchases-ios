//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerFactory.swift
//
//  Created by Antonio Pallares on 25/7/25.

import Foundation

enum ProductsManagerFactory {

    // swiftlint:disable:next function_parameter_count
    static func createManager(apiKeyValidationResult: Configuration.APIKeyValidationResult,
                              diagnosticsTracker: DiagnosticsTrackerType?,
                              systemInfo: SystemInfo,
                              backend: Backend,
                              deviceCache: DeviceCache,
                              requestTimeout: TimeInterval
    ) -> ProductsManagerType {
            if apiKeyValidationResult == .simulatedStore {
                return SimulatedStoreProductsManager(backend: backend,
                                                     deviceCache: deviceCache,
                                                     requestTimeout: requestTimeout)
            } else {
                // Get the ruleset from cached offerings if available
                var cachedRuleSet: PriceFormattingRuleSet?
                if let storefrontCountryCode = systemInfo.storefront?.countryCode {
                    cachedRuleSet = deviceCache.cachedOfferings?.response.uiConfig?
                        .priceFormattingRuleSets[storefrontCountryCode]
                }

                // Create a provider initialized with the cached ruleset
                // (can be updated later when offerings are received)
                let priceFormattingRuleSetProvider = PriceFormattingRuleSetProvider(
                    priceFormattingRuleSet: cachedRuleSet
                )

                return ProductsManager(
                    productsRequestFactory: ProductsRequestFactory(),
                    diagnosticsTracker: diagnosticsTracker,
                    systemInfo: systemInfo,
                    requestTimeout: requestTimeout,
                    priceFormattingRuleSetProvider: priceFormattingRuleSetProvider
                )
            }
    }

}
