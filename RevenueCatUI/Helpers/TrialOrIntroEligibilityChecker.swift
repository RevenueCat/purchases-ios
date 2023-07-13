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

    typealias Checker = @Sendable (StoreProduct) async -> IntroEligibilityStatus

    let checker: Checker

    convenience init(purchases: Purchases = .shared) {
        self.init { product in
            guard product.hasIntroDiscount else {
                return .noIntroOfferExists
            }

            return await purchases.checkTrialOrIntroDiscountEligibility(product: product)
        }
    }

    /// Creates an instance with a custom checker, useful for testing or previews.
    init(checker: @escaping Checker) {
        self.checker = checker
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension TrialOrIntroEligibilityChecker {

    func eligibility(for product: StoreProduct) async -> IntroEligibilityStatus {
        return await self.checker(product)
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension StoreProduct {

    var hasIntroDiscount: Bool {
        // Fix-me: this needs to handle other types of intro discounts
        return self.introductoryDiscount != nil
    }

}
