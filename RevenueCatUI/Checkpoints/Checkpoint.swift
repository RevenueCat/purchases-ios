//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Core-owned checkpoint custom value, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointValue = RevenueCat.CheckpointValue
/// Core-owned checkpoint parameters, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointParams = RevenueCat.CheckpointParams

/// Information about a checkpoint that was hit.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointInfo)
#endif
@_spi(Internal) public final class CheckpointInfo: NSObject, @unchecked Sendable {

    /// The identifier of the checkpoint that was hit.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let identifier: String

    /// The parameters supplied when the checkpoint was hit.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let params: CheckpointParams

    /// Creates checkpoint information for an identifier and its parameters.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointInfo else { return false }
        return self.identifier == other.identifier && self.params == other.params
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.identifier)
        hasher.combine(self.params)
        return hasher.finalize()
    }

    public override var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// The reason no experience was served for a checkpoint.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointNoActionReason)
#endif
@_spi(Internal) public final class CheckpointNoActionReason: NSObject, @unchecked Sendable {

    /// The value identifying the reason.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let value: String

    /// No targeting rule matched.
    public static let noMatch = CheckpointNoActionReason(value: "NO_MATCH")
    /// The customer was assigned to a holdout.
    public static let holdout = CheckpointNoActionReason(value: "HOLDOUT")
    /// The customer reached the configured frequency cap.
    public static let frequencyCapped = CheckpointNoActionReason(value: "FREQUENCY_CAPPED")
    /// Checkpoint configuration could not be loaded.
    public static let configurationUnavailable = CheckpointNoActionReason(value: "CONFIGURATION_UNAVAILABLE")
    /// Checkpoints are disabled.
    public static let disabled = CheckpointNoActionReason(value: "DISABLED")

    init(value: String) {
        self.value = value
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointNoActionReason)?.value == self.value
    }

    public override var hash: Int { return self.value.hashValue }
    public override var description: String { return self.value }

}

/// Base class for the result of hitting a checkpoint.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointResult)
#endif
@_spi(Internal) public class CheckpointResult: NSObject {

    /// Information about the checkpoint that produced this result.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let checkpoint: CheckpointInfo

    init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
        super.init()
    }

    public override var description: String {
        return "CheckpointResult(checkpoint=\(self.checkpoint))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointResult else { return false }
        return type(of: self) == type(of: other) && self.checkpoint == other.checkpoint
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(type(of: self)))
        hasher.combine(self.checkpoint)
        return hasher.finalize()
    }

}

/// A checkpoint-triggered paywall was presented and finished.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallPresentedResult)
#endif
@_spi(Internal) public final class CheckpointPaywallPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented paywall.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let paywallOutcome: CheckpointPaywallOutcome

    init(checkpoint: CheckpointInfo, paywallOutcome: CheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "PaywallPresented(checkpoint=\(self.checkpoint), paywallOutcome=\(self.paywallOutcome))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointPaywallPresentedResult else { return false }
        return self.checkpoint == other.checkpoint && self.paywallOutcome == other.paywallOutcome
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.checkpoint)
        hasher.combine(self.paywallOutcome)
        return hasher.finalize()
    }

}

/// Nothing was served for a checkpoint.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointNoActionResult)
#endif
@_spi(Internal) public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let reason: CheckpointNoActionReason

    init(checkpoint: CheckpointInfo, reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

    public override var description: String {
        return "NoAction(checkpoint=\(self.checkpoint), reason=\(self.reason))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointNoActionResult else { return false }
        return self.checkpoint == other.checkpoint && self.reason == other.reason
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.checkpoint)
        hasher.combine(self.reason)
        return hasher.finalize()
    }

}

/// Base class for the terminal result of a checkpoint-presented paywall.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallOutcome)
#endif
@_spi(Internal) public class CheckpointPaywallOutcome: NSObject {

    fileprivate override init() { super.init() }

    /// A debug description of the paywall outcome.
    public override var description: String { return "CheckpointPaywallOutcome" }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointPaywallOutcome else { return false }
        return type(of: self) == type(of: other)
    }

    public override var hash: Int { return ObjectIdentifier(type(of: self)).hashValue }

}

/// The customer dismissed the paywall.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallDismissedOutcome)
#endif
@_spi(Internal) public final class CheckpointPaywallDismissedOutcome: CheckpointPaywallOutcome {

    /// The dismissed paywall outcome.
    public static let shared = CheckpointPaywallDismissedOutcome()

    private override init() { super.init() }

    public override var description: String { return "Dismissed" }

}

/// The customer completed a purchase.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallPurchasedOutcome)
#endif
@_spi(Internal) public final class CheckpointPaywallPurchasedOutcome: CheckpointPaywallOutcome {

    /// Customer information after the completed purchase.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let customerInfo: CustomerInfo

    /// Creates a purchased outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    public override var description: String { return "Purchased" }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointPaywallPurchasedOutcome)?.customerInfo.isEqual(self.customerInfo) == true
    }

    public override var hash: Int { return self.customerInfo.hash }

}

/// The customer restored purchases.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallRestoredOutcome)
#endif
@_spi(Internal) public final class CheckpointPaywallRestoredOutcome: CheckpointPaywallOutcome {

    /// Customer information after restoring purchases.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let customerInfo: CustomerInfo

    /// Creates a restored outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    public override var description: String { return "Restored" }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointPaywallRestoredOutcome)?.customerInfo.isEqual(self.customerInfo) == true
    }

    public override var hash: Int { return self.customerInfo.hash }

}

/// The paywall ended with an error.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointPaywallErrorOutcome)
#endif
@_spi(Internal) public final class CheckpointPaywallErrorOutcome: CheckpointPaywallOutcome {

    /// The error that ended the checkpoint experience.
#if ENABLE_CHECKPOINTS_OBJC
    @objc
#endif
    public let error: PublicError

    /// Creates a paywall error outcome.
    public init(error: PublicError) {
        self.error = error
        super.init()
    }

    public override var description: String { return "Error(error=\(self.error))" }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointPaywallErrorOutcome)?.error.isEqual(self.error) == true
    }

    public override var hash: Int { return self.error.hash }

}

/// Global listener for checkpoint activity. All methods are called on the main thread.
@_spi(Internal) public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)
    /// The checkpoint completed and its result was returned.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult)

}

@_spi(Internal) public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}
    /// Default no-op implementation.
    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

}
