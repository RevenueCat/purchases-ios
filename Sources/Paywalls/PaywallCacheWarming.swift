//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCacheWarming.swift
//
//  Created by Nacho Soto on 8/7/23.

import Foundation

protocol PaywallCacheWarmingType: Sendable {

    func warmUpEligibilityCache(offerings: Offerings)

}

final class PaywallCacheWarming: PaywallCacheWarmingType {

    private let introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType

    init(introEligibiltyChecker: TrialOrIntroPriceEligibilityCheckerType) {
        self.introEligibiltyChecker = introEligibiltyChecker
    }

    func warmUpEligibilityCache(offerings: Offerings) {
        let productIdentifiers = Set<String>(
            offerings
                .all
                .values
                .lazy
                .flatMap(\.productIdentifiersInPaywall)
        )

        guard !productIdentifiers.isEmpty else { return }

        Logger.debug(Strings.eligibility.warming_up_eligibility_cache(products: productIdentifiers))
        self.introEligibiltyChecker.checkEligibility(productIdentifiers: productIdentifiers) { _ in }
    }

}

private extension Offering {

    var productIdentifiersInPaywall: Set<String> {
        guard let paywall = self.paywall else { return [] }

        let packageTypes = Set(paywall.config.packages)
        return Set(
            self.availablePackages
                .lazy
                .filter { packageTypes.contains($0.identifier) }
                .map(\.storeProduct.productIdentifier)
        )
    }

}
