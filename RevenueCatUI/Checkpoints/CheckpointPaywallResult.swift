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

    static let shared = CheckpointPaywallDismissedOutcome()

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

    init(customerInfo: CustomerInfo) {
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

    init(customerInfo: CustomerInfo) {
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

    init(error: PublicError) {
        self.error = error
        super.init()
    }

    public override var description: String { return "Error(error=\(self.error))" }

    public override func isEqual(_ object: Any?) -> Bool {
        return (object as? CheckpointPaywallErrorOutcome)?.error.isEqual(self.error) == true
    }

    public override var hash: Int { return self.error.hash }

}
