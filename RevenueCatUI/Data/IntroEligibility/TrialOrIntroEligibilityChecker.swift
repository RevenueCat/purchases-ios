//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroEligibilityChecker.swift
//
//  Created by Nacho Soto on 7/13/23.

import Combine
import Foundation
import RevenueCat

// swiftlint:disable:next missing_docs
@_spi(Internal) public final class TrialOrIntroEligibilityChecker: ObservableObject {

    // swiftlint:disable:next missing_docs
    @_spi(Internal) public typealias Checker = @Sendable ([Package]) async -> [Package: IntroEligibilityStatus]

    /// `false` if this `TrialOrIntroEligibilityChecker` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    let checker: Checker

    convenience init(purchases: Purchases = .shared) {
        self.init {
            return await purchases.checkTrialOrIntroDiscountEligibility(packages: $0)
                .mapValues(\.status)
        }
    }

    /// Creates an instance with a custom checker, useful for testing or previews.
    @_spi(Internal) public init(isConfigured: Bool = true, checker: @escaping Checker) {
        self.isConfigured = isConfigured
        self.checker = checker
    }

    static func `default`() -> Self {
        return Purchases.isConfigured ? .init() : .notConfigured()
    }

    private static func notConfigured() -> Self {
        return .init(isConfigured: false) { _ in
            return [:]
        }
    }

}

extension TrialOrIntroEligibilityChecker {

    func eligibility(for package: Package) async -> IntroEligibilityStatus {
        return await self.eligibility(for: [package])[package] ?? .unknown
    }

    /// Computes eligibility for a list of packages in parallel, returning them all in a dictionary.
    func eligibility(for packages: [Package]) async -> [Package: IntroEligibilityStatus] {
        return await self.checker(packages)
    }

}

extension StoreProduct {

    var hasIntroDiscount: Bool {
        // Fix-me: this needs to handle other types of intro discounts
        return self.introductoryDiscount != nil
    }

}
