//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPaywallResult.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// A checkpoint-triggered paywall was presented and finished.
@_spi(CheckpointsInternal)
public final class CheckpointPaywallPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented paywall.
    public let paywallOutcome: CheckpointPaywallOutcome

    init(checkpoint: CheckpointInfo, paywallOutcome: CheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "PaywallPresented(checkpoint=\(self.checkpoint), paywallOutcome=\(self.paywallOutcome))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointPaywallPresentedResult else { return false }
        return self.checkpoint == other.checkpoint && self.paywallOutcome == other.paywallOutcome
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.checkpoint)
        hasher.combine(self.paywallOutcome)
    }

}

/// Base class for the terminal result of a checkpoint-presented paywall.
@_spi(CheckpointsInternal)
public class CheckpointPaywallOutcome: Equatable, Hashable, CustomStringConvertible {

    fileprivate init() {}

    /// A debug description of the paywall outcome.
    public var description: String { return "CheckpointPaywallOutcome" }

    /// Returns whether two paywall outcomes are equal.
    public static func == (lhs: CheckpointPaywallOutcome, rhs: CheckpointPaywallOutcome) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        return type(of: self) == type(of: other)
    }

    /// Hashes the paywall outcome.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: self)))
    }

}

/// The customer dismissed the paywall.
@_spi(CheckpointsInternal)
public final class CheckpointPaywallDismissedOutcome: CheckpointPaywallOutcome {

    static let shared = CheckpointPaywallDismissedOutcome()

    private override init() { super.init() }

    public override var description: String { return "Dismissed" }

}

/// The customer completed a purchase.
@_spi(CheckpointsInternal)
public final class CheckpointPaywallPurchasedOutcome: CheckpointPaywallOutcome {

    /// Customer information after the completed purchase.
    public let customerInfo: CustomerInfo

    init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    public override var description: String { return "Purchased" }

    override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        return (other as? CheckpointPaywallPurchasedOutcome)?.customerInfo.isEqual(self.customerInfo) == true
    }

    public override func hash(into hasher: inout Hasher) { hasher.combine(self.customerInfo.hash) }

}

/// The customer restored purchases.
@_spi(CheckpointsInternal)
public final class CheckpointPaywallRestoredOutcome: CheckpointPaywallOutcome {

    /// Customer information after restoring purchases.
    public let customerInfo: CustomerInfo

    init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    public override var description: String { return "Restored" }

    override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        return (other as? CheckpointPaywallRestoredOutcome)?.customerInfo.isEqual(self.customerInfo) == true
    }

    public override func hash(into hasher: inout Hasher) { hasher.combine(self.customerInfo.hash) }

}

/// The paywall ended with an error.
@_spi(CheckpointsInternal)
public final class CheckpointPaywallErrorOutcome: CheckpointPaywallOutcome {

    /// The error that ended the checkpoint experience.
    public let error: PublicError

    init(error: PublicError) {
        self.error = error
        super.init()
    }

    public override var description: String { return "Error(error=\(self.error))" }

    override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        return (other as? CheckpointPaywallErrorOutcome)?.error.isEqual(self.error) == true
    }

    public override func hash(into hasher: inout Hasher) { hasher.combine(self.error.hash) }

}
