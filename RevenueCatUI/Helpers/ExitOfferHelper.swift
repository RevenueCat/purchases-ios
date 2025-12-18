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

    /// Fetches the exit offer offering for the given offering, if configured.
    /// - Parameter offering: The offering to check for exit offers
    /// - Returns: The exit offer's `Offering` if found and successfully fetched, `nil` otherwise
    @MainActor
    static func fetchExitOfferOffering(for offering: Offering) async -> Offering? {
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
                Logger.debug(Strings.prefetched_exit_offer(exitOfferOfferingId))
            } else {
                Logger.warning(Strings.exit_offer_not_found(exitOfferOfferingId))
            }

            return exitOffering
        } catch {
            Logger.error(Strings.error_loading_exit_offer(error))
            return nil
        }
    }

}

// MARK: - Offering Extension

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    /// Returns the exit offer's offering identifier, checking V2 paywalls first then V1.
    var exitOfferOfferingId: String? {
        // Check V2 paywalls first, then fall back to V1 paywalls
        return self.paywallComponents?.data.exitOffers?.dismiss?.offeringId
            ?? self.paywall?.exitOffers?.dismiss?.offeringId
    }

}

#endif
