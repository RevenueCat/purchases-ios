//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdMobSSVPollStatus.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

/// Result of a single AdMob SSV status poll. Returned by
/// `Purchases.pollAdMobSSVStatus(clientTransactionID:)` and consumed by
/// RC-shipped ad adapters (e.g. `RevenueCatAdMob`).
@_spi(Internal) public struct AdMobSSVPollStatus: Equatable, Sendable {

    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // Struct with static cases (rather than `enum`) so future additions are not
    // source-breaking — the SDK is built without library evolution.

    /// AdMob's SSV postback was received and validated by the backend.
    public static let validated = AdMobSSVPollStatus("validated")

    /// AdMob's SSV postback has not yet arrived (or is still being processed).
    /// The caller is expected to keep polling until the status becomes terminal
    /// or the caller's own retry budget is exhausted.
    public static let pending = AdMobSSVPollStatus("pending")

    /// AdMob's SSV postback was received but rejected by the backend.
    public static let failed = AdMobSSVPollStatus("failed")

}
