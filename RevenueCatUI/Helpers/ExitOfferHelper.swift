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

@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum ExitOfferHelper {

    /// Fetches and validates the exit offer offering for the given offering ID.
    /// Returns `nil` if the offering ID is not found, matches the current offering, or fetching fails.
    /// - Parameters:
    ///   - offeringId: The offering identifier of the exit offer.
    ///   - currentOfferingId: The currently displayed offering identifier.
    /// - Returns: The exit offer's `Offering` if valid, `nil` otherwise.
    @MainActor
    static func fetchValidExitOffer(offeringId: String, currentOfferingId: String) async -> Offering? {
        guard Purchases.isConfigured else { return nil }

        do {
            let allOfferings = try await Purchases.shared.offerings()
            guard let exitOffering = Self.exitOffer(offeringId: offeringId, from: allOfferings) else {
                Logger.warning(Strings.exitOfferNotFound(offeringId))
                return nil
            }
            guard exitOffering.identifier != currentOfferingId else {
                Logger.warning(Strings.exitOfferSameAsCurrent)
                return nil
            }
            Logger.debug(Strings.prefetchedExitOffer(offeringId))
            return exitOffering
        } catch {
            Logger.error(Strings.errorLoadingExitOffer(error))
            return nil
        }
    }
    /// Fetches and validates the exit offer offering for the given offering.
    /// Returns `nil` if:
    /// - No exit offer is configured
    /// - The exit offer is the same as the current offering
    /// - Fetching fails
    /// - Parameter offering: The offering to check for exit offers
    /// - Returns: The exit offer's `Offering` if valid and different from current, `nil` otherwise
    @MainActor
    static func fetchValidExitOffer(for offering: Offering) async -> Offering? {
        guard let exitOfferOfferingId = offering.exitOfferOfferingId else {
            return nil
        }

        return await Self.fetchValidExitOffer(
            offeringId: exitOfferOfferingId,
            currentOfferingId: offering.identifier
        )
    }

    static func validExitOffer(
        offeringId: String,
        currentOfferingId: String,
        from offerings: Offerings
    ) -> Offering? {
        guard let exitOffering = Self.exitOffer(offeringId: offeringId, from: offerings),
              exitOffering.identifier != currentOfferingId else {
            return nil
        }
        return exitOffering
    }

    static func exitOffer(offeringId: String, from offerings: Offerings) -> Offering? {
        return offerings.offering(identifier: offeringId)
    }

}

// MARK: - Offering Extension

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    var exitOfferOfferingId: String? {
        return self.paywallComponents?.data.exitOffers?.dismiss?.offeringId
    }

}

#endif
