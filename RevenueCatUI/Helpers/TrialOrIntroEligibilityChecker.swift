//
//  TrialOrIntroEligibilityChecker.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import RevenueCat

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
final class TrialOrIntroEligibilityChecker: ObservableObject {

    typealias Checker = @Sendable ([Package]) async -> [Package: IntroEligibilityStatus]

    let checker: Checker

    convenience init(purchases: Purchases = .shared) {
        self.init {
            return await purchases.checkTrialOrIntroDiscountEligibility(packages: $0)
                .mapValues(\.status)
        }
    }

    /// Creates an instance with a custom checker, useful for testing or previews.
    init(checker: @escaping Checker) {
        self.checker = checker
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension TrialOrIntroEligibilityChecker {

    func eligibility(for package: Package) async -> IntroEligibilityStatus {
        return await self.eligibility(for: [package])[package] ?? .unknown
    }

    /// Computes eligibility for a list of packages in parallel, returning them all in a dictionary.
    func eligibility(for packages: [Package]) async -> [Package: IntroEligibilityStatus] {
        return await self.checker(packages)
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension StoreProduct {

    var hasIntroDiscount: Bool {
        // Fix-me: this needs to handle other types of intro discounts
        return self.introductoryDiscount != nil
    }

}
