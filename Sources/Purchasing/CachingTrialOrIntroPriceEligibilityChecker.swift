//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CachingTrialOrIntroPriceEligibilityChecker.swift
//
//  Created by Nacho Soto on 10/27/22.

import Foundation

// swiftlint:disable type_name

/// `TrialOrIntroPriceEligibilityCheckerType` decorator that adds caching behavior on each request.
class CachingTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private let checker: TrialOrIntroPriceEligibilityCheckerType

    private let cache: Atomic<[String: IntroEligibility]> = .init([:])

    /// Creates a `CachingTrialOrIntroPriceEligibilityChecker` wrapping the underlying checker,
    /// or returns `checker` if it already is this type.
    static func create(
        with checker: TrialOrIntroPriceEligibilityCheckerType
    ) -> CachingTrialOrIntroPriceEligibilityChecker {
        if let checker = checker as? Self {
            return checker
        } else {
            return CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        }
    }

    init(checker: TrialOrIntroPriceEligibilityCheckerType) {
        self.checker = checker
    }

    func clearCache() {
        Logger.debug(Strings.eligibility.clearing_intro_eligibility_cache)

        self.cache.value.removeAll(keepingCapacity: false)
    }

}

extension CachingTrialOrIntroPriceEligibilityChecker {

    func checkEligibility(
        productIdentifiers: [String],
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        guard !productIdentifiers.isEmpty else {
            completion([:])
            return
        }

        let uniqueProductIdentifiers = Set(productIdentifiers)

        // Note: this can suffer from race conditions, but the only downside is performing concurrent requests
        // multiple times instead of returning the cached result on the second one.
        // It's a fine compromise to keep this implementaton simpler.
        let cached = self.cache.value.filter { uniqueProductIdentifiers.contains($0.key) }

        if !cached.isEmpty {
            Logger.debug(Strings.eligibility.found_cached_eligibility_for_products(Set(cached.keys)))
        }

        let missingProducts = uniqueProductIdentifiers.subtracting(cached.keys)

        if missingProducts.isEmpty {
            completion(cached)
        } else {
            self.checker.checkEligibility(productIdentifiers: Array(missingProducts)) { result in
                let productsToCache = result.filter { $0.value.shouldCache }

                Logger.debug(Strings.eligibility.caching_intro_eligibility_for_products(Set(productsToCache.keys)))
                self.cache.value += productsToCache

                completion(cached + result)
            }
        }
    }

}

// MARK: - Private

private extension IntroEligibility {

    var shouldCache: Bool {
        switch self.status {
        case .noIntroOfferExists, .ineligible, .eligible: return true
        case .unknown: return false
        }
    }

}
