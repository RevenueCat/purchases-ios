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

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageContext: ObservableObject {

    struct VariableContext {

        let mostExpensivePricePerMonth: Double?
        let showZeroDecimalPlacePrices: Bool

        init(packages: [Package], showZeroDecimalPlacePrices: Bool = true) {
            let mostExpensivePricePerMonth = Self.mostExpensivePricePerMonth(in: packages)
            self.init(
                mostExpensivePricePerMonth: mostExpensivePricePerMonth,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )
        }

        init(mostExpensivePricePerMonth: Double? = nil, showZeroDecimalPlacePrices: Bool = true) {
            self.mostExpensivePricePerMonth = mostExpensivePricePerMonth
            self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
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

    }

    let introOfferEligibilityContext: IntroOfferEligibilityContext
    let paywallPromoOfferCache: PaywallPromoOfferCache

    @Published var package: Package?
    @Published var variableContext: VariableContext
    @Published var isEligibleForIntroOffer: Bool = false
    @Published var isEligibleForPromoOffer: Bool = false


    init(
        introOfferEligibilityContext: IntroOfferEligibilityContext,
        paywallPromoOfferCache: PaywallPromoOfferCache,
        package: Package?,
        variableContext: VariableContext
    ) {
        self.introOfferEligibilityContext = introOfferEligibilityContext
        self.paywallPromoOfferCache = paywallPromoOfferCache

        self.package = package
        self.variableContext = variableContext

        Task { @MainActor in
            await self.update(package: package, variableContext: variableContext)
        }
    }

    @MainActor
    func update(package: Package?, variableContext: VariableContext) async {
        self.package = package
        self.variableContext = variableContext

        let thing1 = self.introOfferEligibilityContext.isEligible(
            package: package
        )
        if thing1 != self.isEligibleForIntroOffer {
            self.isEligibleForIntroOffer = thing1
        }
        let thing2 = await self.paywallPromoOfferCache.isMostLikelyEligible(
            for: package
        )
        if thing2 != self.isEligibleForPromoOffer {
            self.isEligibleForPromoOffer = thing2
        }
    }

}

#endif
