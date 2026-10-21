//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointResult.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// The result of passing a checkpoint.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CheckpointResult: Sendable {

    /// Information about the presented flow, or `nil` when the checkpoint had nothing to present.
    public let flow: FlowResult?

    /// The customer's information once the checkpoint is passed: synced with what they obtained when the presented
    /// flow ended with a purchase or restore, the latest known otherwise.
    public let customer: CustomerInfo

    init(flow: FlowResult?, customer: CustomerInfo) {
        self.flow = flow
        self.customer = customer
    }

    /// Returns the entitlement with `identifier` that was obtained while the flow was presented.
    public func obtainedEntitlement(_ identifier: String) -> ObtainedEntitlement? {
        return self.flow?.obtainedEntitlement(identifier)
    }

    /// Returns whether the entitlement with `identifier` was obtained while the flow was presented.
    public func didObtainEntitlement(_ identifier: String) -> Bool {
        return self.obtainedEntitlement(identifier) != nil
    }

    /// Returns the product with `identifier` that was newly observed after the flow completed.
    ///
    /// `identifier` is the product's store identifier. When more than one billing plan of a product was obtained,
    /// the plain identifier returns the up-front plan; suffix it with `:` and the billing plan type
    /// (`"com.app.annual:monthly"`) to select another.
    public func obtainedProduct(_ identifier: String) -> ObtainedProduct? {
        return self.flow?.obtainedProduct(identifier)
    }

    /// Returns whether the product with `identifier` was newly observed after the flow completed. See
    /// ``obtainedProduct(_:)`` for the identifier's format.
    public func didObtainProduct(_ identifier: String) -> Bool {
        return self.obtainedProduct(identifier) != nil
    }

    /// Returns whether the customer holds an active entitlement with `identifier` according to ``customer``:
    /// obtained during this checkpoint or already theirs before it.
    public func hasEntitlement(_ identifier: String) -> Bool {
        return self.customer.entitlements.active[identifier] != nil
    }

}
