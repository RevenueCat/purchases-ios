//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WinBackOfferEligibilityCalculatorType.swift
//
//  Created by Will Taylor on 10/31/24.

import Foundation

/// A protocol defining functions to calculate eligible win-back offers for a given product.
///
/// Implementations of this protocol can be used to determine eligibility for win-back offers, which are designed to
/// re-engage users who may have previously canceled or lapsed in their subscriptions.
/// - Availability: iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
protocol WinBackOfferEligibilityCalculatorType {

    /// Determines the eligible win-back offers for a specified product.
    ///
    /// - Parameter product: The `StoreProduct` instance representing the product to check for
    /// win-back offer eligibility.
    /// - Returns: An array of eligible `WinBackOffer` objects.
    ///
    /// This async variant provides a convenient way to work with eligibility checks in async contexts.
    ///
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func eligibleWinBackOffers(
        forProduct product: StoreProduct
    ) async throws -> [WinBackOffer]
}
