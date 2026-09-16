//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ResolvedAdStep.swift
//
//  Created by RevenueCat.

import Foundation

/// An ad step resolved for a checkpoint, with no RevenueCat-managed UI to present. A registered ad
/// presenter decides how to show it.
@_spi(Internal) public struct ResolvedAdStep: Equatable, Sendable {

    /// Identifies the ad to load for this step, in whatever form ``mediator`` expects (an AdMob ad unit id, for
    /// example).
    public let adIdentifier: String

    /// The mediation network configured to serve ``adIdentifier``.
    public let mediator: MediatorName

    /// The ad format ``adIdentifier`` was created for. Ads are format-locked, so a presenter must load
    /// this ad through the matching format's loader.
    public let adFormat: AdFormat

    /// Creates a resolved ad step.
    @_spi(Internal) public init(adIdentifier: String, mediator: MediatorName, adFormat: AdFormat) {
        self.adIdentifier = adIdentifier
        self.mediator = mediator
        self.adFormat = adFormat
    }

}
