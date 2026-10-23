//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

/// A type that can determine `IntroEligibility` for products.
protocol TrialOrIntroPriceEligibilityCheckerType: Sendable {

    func checkEligibility(productIdentifiers: Set<String>, completion: @escaping ReceiveIntroEligibilityBlock)

}

/// A checker whose StoreKit 2 requests can share eligibility work by subscription group.
protocol GroupAwareTrialOrIntroEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    var usesSubscriptionGroupEligibility: Bool { get }

    func checkEligibility(
        productIdentifiers: Set<String>,
        groupEligibilityChecker: SubscriptionGroupEligibilityChecker?,
        completion: @escaping ReceiveIntroEligibilityBlock
    )

}

/// Resolves a StoreKit group check, allowing the caching wrapper to reuse its work and result.
protocol SubscriptionGroupEligibilityChecker: Sendable {

    func eligibility(
        for groupID: String,
        log: IntroEligibilityLog,
        check: @escaping @Sendable (String) async -> Bool
    ) async -> Bool

}

/// Default overload implementation that takes a single `StoreProductType`.
extension TrialOrIntroPriceEligibilityCheckerType {

    func checkEligibility(product: StoreProductType, completion: @escaping (IntroEligibilityStatus) -> Void) {
        self.checkEligibility(productIdentifiers: [product.id]) { eligibility in
            completion(eligibility[product.id]?.status ?? .unknown)
        }
    }

}
