//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExitOfferHelper.swift
//
//  Created by RevenueCat.

import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum ExitOfferHelper {

    /// Fetches and validates the exit offer offering for the given offering.
    /// Returns `nil` if:
    /// - No exit offer is configured
    /// - The exit offer is the same as the current offering
    /// - Fetching fails
    /// - Parameter offering: The offering to check for exit offers
    /// - Returns: The exit offer's `Offering` if valid and different from current, `nil` otherwise
    @MainActor
    static func fetchValidExitOffer(for offering: Offering) async -> Offering? {
        guard let exitOffering = await fetchExitOfferOffering(for: offering) else {
            return nil
        }

        // Don't use exit offer if it's the same as the current offering
        if exitOffering.identifier == offering.identifier {
            Logger.warning(Strings.exitOfferSameAsCurrent)
            return nil
        }

        return exitOffering
    }

    /// Fetches the exit offer offering for the given offering, if configured.
    /// - Parameter offering: The offering to check for exit offers
    /// - Returns: The exit offer's `Offering` if found and successfully fetched, `nil` otherwise
    @MainActor
    private static func fetchExitOfferOffering(for offering: Offering) async -> Offering? {
        guard let exitOfferOfferingId = offering.exitOfferOfferingId else {
            return nil
        }

        guard Purchases.isConfigured else {
            return nil
        }

        do {
            let exitOffering = try await Purchases.shared.offerings()
                .offering(identifier: exitOfferOfferingId)

            if exitOffering != nil {
                Logger.debug(Strings.prefetchedExitOffer(exitOfferOfferingId))
            } else {
                Logger.warning(Strings.exitOfferNotFound(exitOfferOfferingId))
            }

            return exitOffering
        } catch {
            Logger.error(Strings.errorLoadingExitOffer(error))
            return nil
        }
    }

}

// MARK: - Offering Extension

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    /// Returns the exit offer's offering identifier, checking V2 paywalls first then V1.
    var exitOfferOfferingId: String? {
        return self.paywallComponents?.data.exitOffers?.dismiss?.offeringId
    }

}

#endif
