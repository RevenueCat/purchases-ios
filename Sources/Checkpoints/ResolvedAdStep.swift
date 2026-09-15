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

    /// The ad unit identifier configured for this step.
    public let adUnitId: String

    /// The mediation network configured to serve this ad unit.
    public let mediator: MediatorName

    /// Creates a resolved ad step.
    @_spi(Internal) public init(adUnitId: String, mediator: MediatorName) {
        self.adUnitId = adUnitId
        self.mediator = mediator
    }

}
