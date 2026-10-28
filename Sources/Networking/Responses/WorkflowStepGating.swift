//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStepGating.swift
//

import Foundation

/// A parsed workflow gate. Malformed or unknown gates are invalid and prevent checkpoint resolution.
/// Unknown keys are ignored so the backend can add fields without breaking existing SDKs.
@_spi(Internal) public enum WorkflowStepGating: Equatable, Sendable {

    /// The step does not require an entitlement.
    case soft
    /// The step requires one of the specified entitlements.
    case hard(entitlementIdentifiers: Set<String>)
    /// The backend supplied an unreadable gate.
    case invalid

}
