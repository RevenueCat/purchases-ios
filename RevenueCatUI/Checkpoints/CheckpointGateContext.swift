//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointGateContext.swift
//

import Foundation

/// Whether the workflow's gate permits the pending checkpoint to pass.
enum CheckpointGateOutcome: Equatable {
    case notApplicable
    case passed
    case notPassed
}

/// The checkpoint's entitlement baseline, live customer identity, and call-scoped gate reporting channel.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckpointGateContext {

    let initialAppUserID: String
    let initialActiveEntitlementIdentifiers: Set<String>
    let currentAppUserID: @MainActor () -> String
    let onOutcomeChanged: @MainActor (CheckpointGateOutcome) -> Void

}
