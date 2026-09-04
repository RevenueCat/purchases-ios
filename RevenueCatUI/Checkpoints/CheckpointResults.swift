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

/// An entitlement obtained while completing a checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class EntitlementGrant: CustomStringConvertible, @unchecked Sendable {

    /// The identifier of the obtained entitlement.
    public let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }

    /// A debug description of the entitlement grant.
    public var description: String { return "EntitlementGrant(identifier='\(self.identifier)')" }

}

/// The result of evaluating a checkpoint as a gate.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class CheckpointGateResult: CustomStringConvertible, @unchecked Sendable {

    /// Entitlements that became active while completing the checkpoint.
    public let entitlements: [EntitlementGrant]

    /// Why no workflow was presented, if applicable.
    public let noActionReason: CheckpointNoActionReason?

    /// An error that prevented the checkpoint from completing normally.
    public let error: PublicError?

    init(
        entitlements: [EntitlementGrant] = [],
        noActionReason: CheckpointNoActionReason? = nil,
        error: PublicError? = nil
    ) {
        self.entitlements = entitlements
        self.noActionReason = noActionReason
        self.error = error
    }

    /// A debug description of the gate result.
    public var description: String {
        return "CheckpointGateResult(entitlements=\(self.entitlements), " +
            "noActionReason=\(String(describing: self.noActionReason)), error=\(String(describing: self.error)))"
    }

}

/// Base class for the result of evaluating a checkpoint.
///
/// Inspect the concrete result type to determine what happened:
///
/// ```swift
/// let result = await Purchases.shared.checkpoint("onboarding_complete")
///
/// switch result {
/// case let result as CheckpointResult.PaywallPresented:
///     handlePaywallOutcome(result.paywallOutcome)
/// case let result as CheckpointResult.ReceivedOffering:
///     showOffering(result.offering)
/// case let result as CheckpointResult.NoAction:
///     handleNoAction(result.reason)
/// default:
///     // Handle result types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointResult: CustomStringConvertible {

    init() {}

    /// A debug description of the checkpoint result.
    public var description: String {
        return "CheckpointResult"
    }

    /// Nothing was served for a checkpoint.
    public final class NoAction: CheckpointResult {

        /// The reason no experience was served.
        public let reason: CheckpointNoActionReason

        init(reason: CheckpointNoActionReason) {
            self.reason = reason
            super.init()
        }

        public override var description: String {
            return "NoAction(reason=\(self.reason))"
        }

    }

    /// An offering was selected for a checkpoint, with no RevenueCat-managed UI presented. The app decides
    /// whether and how to use it.
    public final class ReceivedOffering: CheckpointResult {

        /// The offering the checkpoint selected.
        public let offering: Offering

        init(offering: Offering) {
            self.offering = offering
            super.init()
        }

        public override var description: String {
            return "ReceivedOffering(offering=\(self.offering.identifier))"
        }

    }

    /// A checkpoint-triggered paywall was presented and finished.
    public final class PaywallPresented: CheckpointResult {

        /// The terminal outcome of the presented paywall.
        public let paywallOutcome: CheckpointPaywallOutcome

        init(paywallOutcome: CheckpointPaywallOutcome) {
            self.paywallOutcome = paywallOutcome
            super.init()
        }

        public override var description: String {
            return "PaywallPresented(paywallOutcome=\(self.paywallOutcome))"
        }

    }

}

/// Base class for the terminal outcome of a checkpoint-presented paywall.
///
/// Inspect the concrete outcome type to determine how the paywall finished:
///
/// ```swift
/// switch result.paywallOutcome {
/// case let outcome as CheckpointPaywallOutcome.Purchased:
///     handlePurchase(outcome.transaction, outcome.customerInfo)
/// case let outcome as CheckpointPaywallOutcome.Restored:
///     handleRestore(outcome.customerInfo)
/// case is CheckpointPaywallOutcome.Dismissed:
///     handleDismissal()
/// case is CheckpointPaywallOutcome.WebCheckoutOpened:
///     handleWebCheckoutOpened()
/// case let outcome as CheckpointPaywallOutcome.Error:
///     handleError(outcome.error)
/// default:
///     // Handle outcome types added in future SDK versions.
///     break
/// }
/// ```
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class CheckpointPaywallOutcome: CustomStringConvertible {

    fileprivate init() {}

    /// A debug description of the paywall outcome.
    public var description: String { return "CheckpointPaywallOutcome" }

    /// The customer dismissed the paywall without a purchase, restore, or error.
    public final class Dismissed: CheckpointPaywallOutcome {

        static let shared = Dismissed()

        private override init() { super.init() }

        public override var description: String { return "Dismissed" }

    }

    /// The customer opened a web checkout from the paywall to pay externally.
    ///
    /// There is no in-app completion signal for the external payment.
    public final class WebCheckoutOpened: CheckpointPaywallOutcome {

        static let shared = WebCheckoutOpened()

        private override init() { super.init() }

        public override var description: String { return "WebCheckoutOpened" }

    }

    /// The customer completed a purchase.
    public final class Purchased: CheckpointPaywallOutcome {

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

    }

    /// The customer restored purchases.
    public final class Restored: CheckpointPaywallOutcome {

        /// Customer information after restoring purchases.
        public let customerInfo: CustomerInfo

        init(customerInfo: CustomerInfo) {
            self.customerInfo = customerInfo
            super.init()
        }

        public override var description: String { return "Restored" }

    }

    /// A purchase or restore failed with an error. Cancellations are reported as
    /// ``Dismissed`` instead.
    public final class Error: CheckpointPaywallOutcome {

        /// The error that ended the checkpoint experience.
        public let error: PublicError

        init(error: PublicError) {
            self.error = error
            super.init()
        }

        public override var description: String { return "Error(error=\(self.error))" }

    }

}
