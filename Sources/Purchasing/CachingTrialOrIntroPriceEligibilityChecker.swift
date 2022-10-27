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
final class CachingTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private let checker: TrialOrIntroPriceEligibilityCheckerType
    private let cache: Atomic<[String: IntroEligibility]> = .init([:])

    init(checker: TrialOrIntroPriceEligibilityCheckerType) {
        self.checker = checker
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

        let missingProducts = uniqueProductIdentifiers.subtracting(cached.keys)

        if missingProducts.isEmpty {
            completion(cached)
        } else {
            self.checker.checkEligibility(productIdentifiers: Array(missingProducts)) { result in
                self.cache.value += result

                completion(cached + result)
            }
        }
    }

}
