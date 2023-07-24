//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockCachingTrialOrIntroPriceEligibilityChecker.swift
//
//  Created by Nacho Soto on 1/5/23.

@testable import RevenueCat

// swiftlint:disable type_name

class MockCachingTrialOrIntroPriceEligibilityChecker: CachingTrialOrIntroPriceEligibilityChecker {

    let checker: MockTrialOrIntroPriceEligibilityChecker

    init(checker: MockTrialOrIntroPriceEligibilityChecker) {
        self.checker = checker

        super.init(checker: self.checker)
    }

    var invokedClearCache = false
    var invokedClearCacheCount = 0

    override func clearCache() {
        self.invokedClearCache = true
        self.invokedClearCacheCount += 1

        super.clearCache()
    }

    var stubbedEligibility: [String: IntroEligibility] = [:]
    var invokedCheckEligibility: Bool = false
    var invokedCheckEligibilityCount = 0
    var invokedCheckEligibilityProducts: [String]?

    override func checkEligibility(
        productIdentifiers: [String],
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        self.invokedCheckEligibility = true
        self.invokedCheckEligibilityCount += 1
        self.invokedCheckEligibilityProducts = productIdentifiers

        completion(self.stubbedEligibility)
    }

}
