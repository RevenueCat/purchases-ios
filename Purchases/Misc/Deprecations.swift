//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Deprecations.swift
//
//  Created by Nacho Soto on 3/8/22.

import Foundation
import StoreKit

// swiftlint:disable line_length missing_docs

public extension Purchases {

    @available(iOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String],
                                              completion: @escaping ([String: IntroEligibility]) -> Void) {
        self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers, completion: completion)
    }

    @available(iOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, introduced: 6.2, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, introduced: 10.15, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String]) async -> [String: IntroEligibility] {
        return await self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
    }

}
