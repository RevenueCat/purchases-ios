//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWinBackOfferEligibilityCalculator.swift
//
//  Created by Will Taylor on 10/31/24.

import Foundation

@testable import RevenueCat

final class MockWinBackOfferEligibilityCalculator: WinBackOfferEligibilityCalculatorType, @unchecked Sendable {

    var eligibleWinBackOffersCalled = false
    var eligibleWinBackOffersCallCount = 0
    var eligibleWinBackOffersProduct: RevenueCat.StoreProduct?

    enum EligibleWinBackOffersResult {
        case error
        case success
    }
    var eligibleWinBackOffersResult: EligibleWinBackOffersResult = .success

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func eligibleWinBackOffers(
        forProduct product: RevenueCat.StoreProduct
    ) async throws -> [WinBackOffer] {
        eligibleWinBackOffersCalled = true
        eligibleWinBackOffersCallCount += 1
        eligibleWinBackOffersProduct = product

        switch self.eligibleWinBackOffersResult {
        case .error:
            throw ErrorUtils.featureNotSupportedWithStoreKit1Error()
        case .success:
            return []
        }
    }
}
