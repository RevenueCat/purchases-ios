//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageContext.swift
//
//  Created by Josh Holtz on 11/14/24.

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageContext: ObservableObject {

    struct VariableContext {

        let packages: [Package]
        let mostExpensivePricePerMonth: Double?
        let showZeroDecimalPlacePrices: Bool
        let hasAnyIntroOffer: Bool

        init(
            packages: [Package],
            showZeroDecimalPlacePrices: Bool = true
        ) {
            let mostExpensivePricePerMonth = Self.mostExpensivePricePerMonth(in: packages)
            let hasAnyIntroOffer = Self.containsIntroOffer(in: packages)
            self.init(
                packages: packages,
                mostExpensivePricePerMonth: mostExpensivePricePerMonth,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
                hasAnyIntroOffer: hasAnyIntroOffer
            )
        }

        init(
            packages: [Package] = [],
            mostExpensivePricePerMonth: Double? = nil,
            showZeroDecimalPlacePrices: Bool = true,
            hasAnyIntroOffer: Bool = false
        ) {
            self.packages = packages
            self.mostExpensivePricePerMonth = mostExpensivePricePerMonth
            self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
            self.hasAnyIntroOffer = hasAnyIntroOffer
        }

        private static func mostExpensivePricePerMonth(in packages: [Package]) -> Double? {
            return packages
                .lazy
                .map(\.storeProduct)
                .compactMap { product in
                    product.pricePerMonth.map {
                        return (
                            product: product,
                            pricePerMonth: $0
                        )
                    }
                }
                .max { productA, productB in
                    return productA.pricePerMonth.doubleValue < productB.pricePerMonth.doubleValue
                }
                .map(\.pricePerMonth.doubleValue)
        }

        private static func containsIntroOffer(in packages: [Package]) -> Bool {
            return packages.contains { package in
                return package.storeProduct.introductoryDiscount != nil
            }
        }

    }

    @Published var package: Package?
    @Published var variableContext: VariableContext

    init(
        package: Package?,
        variableContext: VariableContext
    ) {
        self.package = package
        self.variableContext = variableContext
    }

    @MainActor
    func update(package: Package?, variableContext: VariableContext) {
        self.package = package
        self.variableContext = variableContext
    }

    func packagesForEligibility() -> [Package] {
        if !self.variableContext.packages.isEmpty {
            return self.variableContext.packages
        } else if let package {
            return [package]
        } else {
            return []
        }
    }

    func hasEligiblePromoOffer(using cache: PaywallPromoOfferCache) -> Bool {
        return cache.hasEligibleOffer(in: self.packagesForEligibility())
    }

}

#endif
