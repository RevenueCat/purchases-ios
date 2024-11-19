//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroOfferEligibilityContext.swift
//
//  Created by Josh Holtz on 11/15/24.

import Combine
import RevenueCat

#if PAYWALL_COMPONENTS

@MainActor
class IntroOfferEligibilityContext: ObservableObject {

    private let introEligibilityChecker: TrialOrIntroEligibilityChecker

    @Published
    private(set) var allEligibility: [Package: IntroEligibilityStatus] = [:]

    init(introEligibilityChecker: TrialOrIntroEligibilityChecker) {
        self.introEligibilityChecker = introEligibilityChecker
    }

    func computeEligibility(for packages: [Package]) async {
        let result = await self.introEligibilityChecker.eligibility(for: packages)
        self.allEligibility = result
    }

}

extension IntroOfferEligibilityContext {

    func isEligible(package: Package?) -> Bool {
        guard let package else {
            return false
        }
        return self.allEligibility[package]?.isEligible ?? false
    }

}

#endif
