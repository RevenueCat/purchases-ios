//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

/// Objective-C representation of ``CheckpointParams``.
@_spi(Internal) @objc(RCCheckpointParams)
public final class ObjCCheckpointParams: NSObject {

    /// Custom properties usable in checkpoint targeting rules.
    @objc public let customProperties: NSDictionary

    let swiftValue: CheckpointParams

    /// Creates parameters with custom properties. Unsupported values are dropped.
    @objc public init(customProperties: NSDictionary) {
        let swiftValue = CheckpointParams(
            customProperties: customProperties as? [String: Any] ?? [:]
        )
        self.swiftValue = swiftValue
        self.customProperties = swiftValue.customProperties as NSDictionary
        super.init()
    }

    /// Creates empty checkpoint parameters.
    @objc public override convenience init() {
        self.init(customProperties: [:])
    }

    public override var description: String { return self.swiftValue.description }

}

/// Objective-C representation of ``CheckpointInfo``.
@_spi(Internal) @objc(RCCheckpointInfo)
public final class ObjCCheckpointInfo: NSObject {

    /// The checkpoint identifier.
    @objc public let identifier: String

    /// Parameters supplied when the checkpoint was hit.
    @objc public let params: ObjCCheckpointParams

    init(_ checkpoint: CheckpointInfo) {
        self.identifier = checkpoint.identifier
        self.params = ObjCCheckpointParams(
            customProperties: checkpoint.params.customProperties as NSDictionary
        )
        super.init()
    }

    public override var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// Objective-C representation of ``CheckpointNoActionReason``.
@_spi(Internal) @objc(RCCheckpointNoActionReason)
public final class ObjCCheckpointNoActionReason: NSObject {

    /// The raw no-action reason value.
    @objc public let value: String

    init(_ reason: CheckpointNoActionReason) {
        self.value = reason.value
        super.init()
    }

    public override var description: String { return self.value }

}

/// Base class for Objective-C checkpoint paywall results.
@_spi(Internal) @objc(RCCheckpointPaywallResult)
public class ObjCCheckpointPaywallResult: NSObject {

    fileprivate override init() { super.init() }

    static func wrapping(_ result: CheckpointPaywallResult) -> ObjCCheckpointPaywallResult {
        switch result {
        case is CheckpointPaywallDismissedResult:
            return ObjCCheckpointPaywallDismissedResult()
        case let purchased as CheckpointPaywallPurchasedResult:
            return ObjCCheckpointPaywallPurchasedResult(customerInfo: purchased.customerInfo)
        case let restored as CheckpointPaywallRestoredResult:
            return ObjCCheckpointPaywallRestoredResult(customerInfo: restored.customerInfo)
        case let error as CheckpointPaywallErrorResult:
            return ObjCCheckpointPaywallErrorResult(error: error.error)
        default:
            return ObjCCheckpointPaywallResult()
        }
    }

}

/// Objective-C result indicating that the paywall was dismissed.
@_spi(Internal) @objc(RCCheckpointPaywallDismissedResult)
public final class ObjCCheckpointPaywallDismissedResult: ObjCCheckpointPaywallResult {}

/// Objective-C result indicating that the customer purchased from the paywall.
@_spi(Internal) @objc(RCCheckpointPaywallPurchasedResult)
public final class ObjCCheckpointPaywallPurchasedResult: ObjCCheckpointPaywallResult {

    /// Customer information after the purchase.
    @objc public let customerInfo: CustomerInfo

    fileprivate init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

}

/// Objective-C result indicating that the customer restored purchases from the paywall.
@_spi(Internal) @objc(RCCheckpointPaywallRestoredResult)
public final class ObjCCheckpointPaywallRestoredResult: ObjCCheckpointPaywallResult {

    /// Customer information after restoring purchases.
    @objc public let customerInfo: CustomerInfo

    fileprivate init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

}

/// Objective-C result indicating that the paywall ended with an error.
@_spi(Internal) @objc(RCCheckpointPaywallErrorResult)
public final class ObjCCheckpointPaywallErrorResult: ObjCCheckpointPaywallResult {

    /// The error that ended the paywall.
    @objc public let error: PublicError

    fileprivate init(error: PublicError) {
        self.error = error
        super.init()
    }

}

/// Base class for Objective-C checkpoint call results.
@_spi(Internal) @objc(RCCheckpointResult)
public class ObjCCheckpointResult: NSObject {

    /// Information about the checkpoint that produced this result.
    @objc public let checkpoint: ObjCCheckpointInfo

    fileprivate init(checkpoint: ObjCCheckpointInfo) {
        self.checkpoint = checkpoint
        super.init()
    }

    static func wrapping(_ result: CheckpointResult) -> ObjCCheckpointResult {
        let checkpoint = ObjCCheckpointInfo(result.checkpoint)
        switch result {
        case let presented as CheckpointPaywallPresentedResult:
            return ObjCCheckpointPaywallPresentedResult(
                checkpoint: checkpoint,
                paywallResult: .wrapping(presented.paywallResult)
            )
        case let noAction as CheckpointNoActionResult:
            return ObjCCheckpointNoActionResult(
                checkpoint: checkpoint,
                reason: ObjCCheckpointNoActionReason(noAction.reason)
            )
        default:
            return ObjCCheckpointResult(checkpoint: checkpoint)
        }
    }

}

/// Objective-C result indicating that a checkpoint-triggered paywall was presented.
@_spi(Internal) @objc(RCCheckpointPaywallPresentedResult)
public final class ObjCCheckpointPaywallPresentedResult: ObjCCheckpointResult {

    /// The terminal result of the presented paywall.
    @objc public let paywallResult: ObjCCheckpointPaywallResult

    fileprivate init(checkpoint: ObjCCheckpointInfo, paywallResult: ObjCCheckpointPaywallResult) {
        self.paywallResult = paywallResult
        super.init(checkpoint: checkpoint)
    }

}

/// Objective-C result indicating that nothing was served for a checkpoint.
@_spi(Internal) @objc(RCCheckpointNoActionResult)
public final class ObjCCheckpointNoActionResult: ObjCCheckpointResult {

    /// The reason nothing was served.
    @objc public let reason: ObjCCheckpointNoActionReason

    fileprivate init(checkpoint: ObjCCheckpointInfo, reason: ObjCCheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

}
