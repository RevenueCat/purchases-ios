//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowGateEvaluator.swift
//

@_spi(Internal) import RevenueCat

extension WorkflowStepGating {

    /// Whether the gate can block the checkpoint. An `.invalid` gate fails closed and never passes.
    var isEnforced: Bool {
        switch self {
        case .hard, .invalid: return true
        case .soft: return false
        }
    }

    func isSatisfied(by activeEntitlementIdentifiers: Set<String>) -> Bool {
        switch self {
        case let .hard(entitlementIdentifiers):
            return !entitlementIdentifiers.isDisjoint(with: activeEntitlementIdentifiers)
        case .invalid:
            return false
        case .soft:
            return true
        }
    }

}
