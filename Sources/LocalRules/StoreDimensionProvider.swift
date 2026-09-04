//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreDimensionProvider.swift
//
//  Created by Rick van der Linden on 8/12/26.
//

import Foundation

/// Supplies current App Store information to the local rules engine.
struct StoreDimensionProvider: DimensionProvider {

    let name = "store"

    private let storefrontCountryCodeProvider: @Sendable () async -> String?

    init(
        storefrontCountryCodeProvider: @escaping @Sendable () async -> String? = {
            await Storefront.currentStorefront?.countryCode
        }
    ) {
        self.storefrontCountryCodeProvider = storefrontCountryCodeProvider
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        guard let storefrontCountryCode = await self.storefrontCountryCodeProvider(),
              !storefrontCountryCode.isEmpty else {
            return [:]
        }

        // Storefront country codes use ISO 3166-1 alpha-3 format, such as "USA".
        return ["storefront": .string(storefrontCountryCode)]
    }

}
