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

#endif
