//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint+ObjectiveC.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if ENABLE_CHECKPOINTS_OBJC

/// Objective-C representation of ``CheckpointParams``.
@objc(RCCheckpointParams)
public final class ObjCCheckpointParams: NSObject {

    /// Custom properties usable in checkpoint targeting rules.
    @objc public var customProperties: NSDictionary {
        return self.swiftValue.customProperties.mapValues { $0.foundationValue } as NSDictionary
    }

    let swiftValue: CheckpointParams

    /// Creates parameters with custom properties. Unsupported values are dropped.
    @objc public init(customProperties: NSDictionary) {
        var values: [String: CheckpointValue] = [:]
        for (rawKey, rawValue) in customProperties {
            guard let key = rawKey as? String,
                  let value = CheckpointValue(foundationValue: rawValue) else {
                Logger.warning(
                    "Dropping invalid Objective-C checkpoint custom property: " +
                    String(reflecting: type(of: rawValue))
                )
                continue
            }
            values[key] = value
        }
        self.swiftValue = CheckpointParams(customProperties: values)
        super.init()
    }

    /// Creates empty checkpoint parameters.
    @objc public override convenience init() {
        self.init(customProperties: [:])
    }

    public override var description: String { return self.swiftValue.description }

}

/// Objective-C representation of ``CheckpointInfo``.
@objc(RCCheckpointInfo)
public final class ObjCCheckpointInfo: NSObject {

    /// The checkpoint identifier.
    @objc public let identifier: String

    /// Parameters supplied when the checkpoint was hit.
    @objc public let params: ObjCCheckpointParams

    init(_ checkpoint: CheckpointInfo) {
        self.identifier = checkpoint.identifier
        self.params = ObjCCheckpointParams(
            customProperties: checkpoint.params.customProperties.mapValues { $0.foundationValue } as NSDictionary
        )
        super.init()
    }

    public override var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

/// Objective-C representation of ``CheckpointNoActionReason``.
@objc(RCCheckpointNoActionReason)
public final class ObjCCheckpointNoActionReason: NSObject {

    /// The raw no-action reason value.
    @objc public let value: String

    init(_ reason: CheckpointNoActionReason) {
        self.value = reason.value
        super.init()
    }

    public override var description: String { return self.value }

}

/// Base class for Objective-C checkpoint paywall outcomes.
@objc(RCCheckpointPaywallOutcome)
public class ObjCCheckpointPaywallOutcome: NSObject {

    fileprivate override init() { super.init() }

    static func wrapping(_ outcome: CheckpointPaywallOutcome) -> ObjCCheckpointPaywallOutcome {
        switch outcome {
        case is CheckpointPaywallDismissedOutcome:
            return ObjCCheckpointPaywallDismissedOutcome()
        case let purchased as CheckpointPaywallPurchasedOutcome:
            return ObjCCheckpointPaywallPurchasedOutcome(customerInfo: purchased.customerInfo)
        case let restored as CheckpointPaywallRestoredOutcome:
            return ObjCCheckpointPaywallRestoredOutcome(customerInfo: restored.customerInfo)
        case let error as CheckpointPaywallErrorOutcome:
            return ObjCCheckpointPaywallErrorOutcome(error: error.error)
        default:
            return ObjCCheckpointPaywallOutcome()
        }
    }

}

/// Objective-C result indicating that the paywall was dismissed.
@objc(RCCheckpointPaywallDismissedOutcome)
public final class ObjCCheckpointPaywallDismissedOutcome: ObjCCheckpointPaywallOutcome {}

/// Objective-C result indicating that the customer purchased from the paywall.
@objc(RCCheckpointPaywallPurchasedOutcome)
public final class ObjCCheckpointPaywallPurchasedOutcome: ObjCCheckpointPaywallOutcome {

    /// Customer information after the purchase.
    @objc public let customerInfo: CustomerInfo

    fileprivate init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

}

/// Objective-C result indicating that the customer restored purchases from the paywall.
@objc(RCCheckpointPaywallRestoredOutcome)
public final class ObjCCheckpointPaywallRestoredOutcome: ObjCCheckpointPaywallOutcome {

    /// Customer information after restoring purchases.
    @objc public let customerInfo: CustomerInfo

    fileprivate init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

}

/// Objective-C result indicating that the paywall ended with an error.
@objc(RCCheckpointPaywallErrorOutcome)
public final class ObjCCheckpointPaywallErrorOutcome: ObjCCheckpointPaywallOutcome {

    /// The error that ended the paywall.
    @objc public let error: PublicError

    fileprivate init(error: PublicError) {
        self.error = error
        super.init()
    }

}

/// Base class for Objective-C checkpoint call results.
@objc(RCCheckpointResult)
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
                paywallOutcome: .wrapping(presented.paywallOutcome)
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
@objc(RCCheckpointPaywallPresentedResult)
public final class ObjCCheckpointPaywallPresentedResult: ObjCCheckpointResult {

    /// The terminal outcome of the presented paywall.
    @objc public let paywallOutcome: ObjCCheckpointPaywallOutcome

    fileprivate init(checkpoint: ObjCCheckpointInfo, paywallOutcome: ObjCCheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init(checkpoint: checkpoint)
    }

}

/// Objective-C result indicating that nothing was served for a checkpoint.
@objc(RCCheckpointNoActionResult)
public final class ObjCCheckpointNoActionResult: ObjCCheckpointResult {

    /// The reason nothing was served.
    @objc public let reason: ObjCCheckpointNoActionReason

    fileprivate init(checkpoint: ObjCCheckpointInfo, reason: ObjCCheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

}

#endif
