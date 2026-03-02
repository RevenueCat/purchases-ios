//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExitOffer.swift
//
//  Created by RevenueCat.

import Foundation

/// Represents an exit offer that can be shown when a paywall is dismissed.
public struct ExitOffer: Codable, Sendable, Hashable, Equatable {

    /// The identifier of the offering to show as an exit offer.
    public let offeringId: String

    /// Creates an exit offer with the specified offering identifier.
    /// - Parameter offeringId: The identifier of the offering to show.
    public init(offeringId: String) {
        self.offeringId = offeringId
    }
}

/// Contains exit offers for different dismissal triggers.
public struct ExitOffers: Codable, Sendable, Hashable, Equatable {

    /// The exit offer to show when the paywall is dismissed.
    public let dismiss: ExitOffer?

    /// Creates exit offers configuration.
    /// - Parameter dismiss: The exit offer to show on dismissal.
    public init(dismiss: ExitOffer? = nil) {
        self.dismiss = dismiss
    }

}
