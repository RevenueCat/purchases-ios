//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License;
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointFailureKind.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// What kind of failure was handed to an ``ErrorPresenter``.
///
/// The kind lets the presenter tailor its message to the customer. The SDK determines what happens after error
/// presentation finishes based on the error and the state of the Flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CheckpointFailureKind: Hashable, Sendable {

    private let name: String

    private init(_ name: String) {
        self.name = name
    }

    /// The Flow could not be presented or could not load what it would show.
    public static let flowCouldNotBeShown = Self("flowCouldNotBeShown")

    /// An action in the presented Flow failed, such as a purchase or restore.
    public static let flowActionFailed = Self("flowActionFailed")

    /// The Flow ended, but the SDK could not refresh CustomerInfo to determine which entitlements were granted.
    public static let flowResultSyncFailed = Self("flowResultSyncFailed")

}
