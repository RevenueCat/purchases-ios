//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPresentationID.swift
//
//  Created by Antonio Pallares on 7/30/26.

import Foundation
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallPresentationIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Identifies one presentation of a paywall, so components that cache state outside the SwiftUI
    /// tree can scope it to a single presentation instead of sharing it process-wide.
    ///
    /// `PaywallsV2View` publishes its `paywallSessionID`, which is minted per presentation and re-minted
    /// when a workflow step is re-entered. `nil` outside a Paywalls V2 presentation (previews, tests,
    /// components hosted directly).
    var paywallPresentationID: UUID? {
        get { self[PaywallPresentationIDKey.self] }
        set { self[PaywallPresentationIDKey.self] = newValue }
    }

}
