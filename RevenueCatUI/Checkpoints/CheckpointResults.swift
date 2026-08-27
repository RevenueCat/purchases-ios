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

/// Base class for the result of evaluating a checkpoint.
///
/// Inspect the concrete result type to determine what happened:
///
/// ```swift
/// let result = try await Purchases.shared.checkpoint("onboarding_complete")
///
/// switch result {
/// case let result as CheckpointPaywallPresentedResult:
///     handlePaywallOutcome(result.paywallOutcome)
/// case let result as CheckpointReceivedOfferingResult:
///     showOffering(result.offering)
/// case let result as CheckpointNoActionResult:
///     handleNoAction(result.reason)
/// default:
///     // Handle result types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointResult: Equatable, Hashable, CustomStringConvertible {

    init() {}

    /// A debug description of the checkpoint result.
    public var description: String {
        return "CheckpointResult"
    }

    /// Returns whether two checkpoint results are equal.
    public static func == (lhs: CheckpointResult, rhs: CheckpointResult) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func isEqual(to other: CheckpointResult) -> Bool {
        return type(of: self) == type(of: other)
    }

    /// Hashes the checkpoint result.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: self)))
    }

}

/// Nothing was served for a checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
    public let reason: CheckpointNoActionReason

    init(reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init()
    }

    public override var description: String {
        return "NoAction(reason=\(self.reason))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointNoActionResult else { return false }
        return self.reason == other.reason
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.reason)
    }

}

/// An offering was selected for a checkpoint, with no RevenueCat-managed UI presented. The app decides
/// whether and how to use it.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointReceivedOfferingResult: CheckpointResult {

    /// The offering the checkpoint selected.
    public let offering: Offering

    init(offering: Offering) {
        self.offering = offering
        super.init()
    }

    public override var description: String {
        return "ReceivedOffering(offering=\(self.offering.identifier))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointReceivedOfferingResult else { return false }
        return self.offering == other.offering
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.offering)
    }

}

/// A checkpoint-triggered paywall was presented and finished.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointPaywallPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented paywall.
    public let paywallOutcome: CheckpointPaywallOutcome

    init(paywallOutcome: CheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init()
    }

    public override var description: String {
        return "PaywallPresented(paywallOutcome=\(self.paywallOutcome))"
    }

    override func isEqual(to other: CheckpointResult) -> Bool {
        guard let other = other as? CheckpointPaywallPresentedResult else { return false }
        return self.paywallOutcome == other.paywallOutcome
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.paywallOutcome)
    }

}

/// Base class for the terminal outcome of a checkpoint-presented paywall.
///
/// Inspect the concrete outcome type to determine how the paywall finished:
///
/// ```swift
/// switch result.paywallOutcome {
/// case let outcome as CheckpointPaywallPurchasedOutcome:
///     handlePurchase(outcome.transaction, outcome.customerInfo)
/// case let outcome as CheckpointPaywallRestoredOutcome:
///     handleRestore(outcome.customerInfo)
/// case is CheckpointPaywallDismissedOutcome:
///     handleDismissal()
/// case is CheckpointPaywallWebCheckoutOpenedOutcome:
///     handleWebCheckoutOpened()
/// case let outcome as CheckpointPaywallErrorOutcome:
///     handleError(outcome.error)
/// default:
///     // Handle outcome types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

/// The customer dismissed the paywall without a purchase, restore, or error.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointPaywallDismissedOutcome: CheckpointPaywallOutcome {

    static let shared = CheckpointPaywallDismissedOutcome()

    private override init() { super.init() }

    public override var description: String { return "Dismissed" }

}

/// The customer opened a web checkout from the paywall to pay externally.
///
/// There is no in-app completion signal for the external payment.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
public final class CheckpointPaywallWebCheckoutOpenedOutcome: CheckpointPaywallOutcome {

    static let shared = CheckpointPaywallWebCheckoutOpenedOutcome()

    private override init() { super.init() }

    public override var description: String { return "WebCheckoutOpened" }

}

/// The customer completed a purchase.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointPaywallPurchasedOutcome: CheckpointPaywallOutcome {

    /// The transaction completed by the purchase, if available.
    public let transaction: StoreTransaction?

    /// Customer information after the completed purchase.
    public let customerInfo: CustomerInfo

    init(transaction: StoreTransaction?, customerInfo: CustomerInfo) {
        self.transaction = transaction
        self.customerInfo = customerInfo
        super.init()
    }

    public override var description: String { return "Purchased" }

    override func isEqual(to other: CheckpointPaywallOutcome) -> Bool {
        guard let other = other as? CheckpointPaywallPurchasedOutcome else { return false }
        return self.transaction == other.transaction && self.customerInfo.isEqual(other.customerInfo)
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(self.transaction)
        hasher.combine(self.customerInfo.hash)
    }

}

/// The customer restored purchases.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

/// A purchase or restore failed with an error. Cancellations are reported as
/// ``CheckpointPaywallDismissedOutcome`` instead.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
