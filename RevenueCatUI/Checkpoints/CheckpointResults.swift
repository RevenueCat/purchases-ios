//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointResults.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// An active entitlement reported after completing a checkpoint flow.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ObtainedEntitlement: Hashable, @unchecked Sendable {

    /// Information about the active entitlement reported after the flow.
    public let entitlementInfo: EntitlementInfo

    init(entitlementInfo: EntitlementInfo) {
        self.entitlementInfo = entitlementInfo
    }

    /// Returns whether two obtained entitlements represent the same entitlement identifier.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.entitlementInfo.identifier == rhs.entitlementInfo.identifier
    }

    /// Hashes the entitlement identifier.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.entitlementInfo.identifier)
    }

}

/// The result of completing a checkpoint flow.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct FlowResult: @unchecked Sendable {

    /// Active entitlements present after the flow that were not active in cached customer information before it began.
    ///
    /// The SDK compares the final customer information with the customer information cached before presenting the
    /// flow. When no cached customer information is available, this can include entitlements that were already active
    /// or were obtained from another source.
    public let obtainedEntitlements: Set<ObtainedEntitlement>

    init(obtainedEntitlements: Set<ObtainedEntitlement> = []) {
        self.obtainedEntitlements = obtainedEntitlements
    }

}
