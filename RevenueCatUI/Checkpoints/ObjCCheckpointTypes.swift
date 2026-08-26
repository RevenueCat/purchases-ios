//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ObjCCheckpointTypes.swift
//
//  Created by Rick van der Linden.
//

#if ENABLE_CHECKPOINTS_OBJC

import Foundation
@_spi(Internal) import RevenueCat

#if DEBUG
private enum CheckpointStrings: LogMessage {

    case invalidObjectiveCCustomVariable(Any.Type)

    var description: String {
        switch self {
        case let .invalidObjectiveCCustomVariable(type):
            return "Dropping invalid Objective-C checkpoint custom variable: \(String(reflecting: type))"
        }
    }

    var category: String { return "checkpoints" }

}
#endif

@available(iOS 15.0, *)
extension CheckpointCallParams {

    convenience init(objectiveCCustomVariables: NSDictionary?) {
        var values: [String: CustomVariableValue] = [:]
        for (rawKey, rawValue) in objectiveCCustomVariables ?? [:] {
            guard let key = rawKey as? String,
                  let value = CustomVariableValue(foundationValue: rawValue) else {
                #if DEBUG
                Logger.warning(CheckpointStrings.invalidObjectiveCCustomVariable(type(of: rawValue)))
                #endif
                continue
            }
            values[key] = value
        }
        self.init(customVariables: values)
    }

}

/// Objective-C-compatible checkpoint information.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointInfo)
public final class ObjCCheckpointInfo: NSObject {

    init(_ value: CheckpointInfo) {
        self.identifier = value.identifier
        self.customVariables = value.customVariables.mapValues { $0.foundationValue } as NSDictionary
        super.init()
    }

    /// The identifier of the checkpoint that was hit.
    @objc public let identifier: String

    /// The custom variables supplied when the checkpoint was hit.
    @objc public let customVariables: NSDictionary

}

/// Objective-C-compatible reason that no experience was served.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointNoActionReason)
public final class ObjCCheckpointNoActionReason: NSObject {

    init(_ value: CheckpointNoActionReason) {
        self.value = value.value
        super.init()
    }

    /// The value identifying the reason.
    @objc public let value: String

}

/// Objective-C-compatible base checkpoint result.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointResult)
public class ObjCCheckpointResult: NSObject {

    init(_ value: CheckpointResult) {
        self.checkpoint = ObjCCheckpointInfo(value.checkpoint)
        super.init()
    }

    /// Information about the checkpoint that produced this result.
    @objc public let checkpoint: ObjCCheckpointInfo

    static func wrapping(_ value: CheckpointResult) -> ObjCCheckpointResult {
        switch value {
        case let result as CheckpointPaywallPresentedResult:
            return ObjCCheckpointPaywallPresentedResult(result)
        case let result as CheckpointReceivedOfferingResult:
            return ObjCCheckpointReceivedOfferingResult(result)
        case let result as CheckpointNoActionResult:
            return ObjCCheckpointNoActionResult(result)
        default:
            return ObjCCheckpointResult(value)
        }
    }

}

/// Objective-C-compatible checkpoint result carrying an app-owned offering.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointReceivedOfferingResult)
public final class ObjCCheckpointReceivedOfferingResult: ObjCCheckpointResult {

    init(_ value: CheckpointReceivedOfferingResult) {
        self.offering = value.offering
        super.init(value)
    }

    /// The offering the checkpoint selected.
    @objc public let offering: Offering

}

/// Objective-C-compatible no-action checkpoint result.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointNoActionResult)
public final class ObjCCheckpointNoActionResult: ObjCCheckpointResult {

    init(_ value: CheckpointNoActionResult) {
        self.reason = ObjCCheckpointNoActionReason(value.reason)
        super.init(value)
    }

    /// The reason no experience was served.
    @objc public let reason: ObjCCheckpointNoActionReason

}

/// Objective-C-compatible checkpoint-triggered paywall result.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallPresentedResult)
public final class ObjCCheckpointPaywallPresentedResult: ObjCCheckpointResult {

    init(_ value: CheckpointPaywallPresentedResult) {
        self.paywallOutcome = ObjCCheckpointPaywallOutcome.wrapping(value.paywallOutcome)
        super.init(value)
    }

    /// The terminal outcome of the presented paywall.
    @objc public let paywallOutcome: ObjCCheckpointPaywallOutcome

}

/// Objective-C-compatible base paywall outcome.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallOutcome)
public class ObjCCheckpointPaywallOutcome: NSObject {

    static func wrapping(_ value: CheckpointPaywallOutcome) -> ObjCCheckpointPaywallOutcome {
        switch value {
        case is CheckpointPaywallDismissedOutcome:
            return ObjCCheckpointPaywallDismissedOutcome()
        case let outcome as CheckpointPaywallPurchasedOutcome:
            return ObjCCheckpointPaywallPurchasedOutcome(outcome)
        case let outcome as CheckpointPaywallRestoredOutcome:
            return ObjCCheckpointPaywallRestoredOutcome(outcome)
        case let outcome as CheckpointPaywallErrorOutcome:
            return ObjCCheckpointPaywallErrorOutcome(outcome)
        default:
            return ObjCCheckpointPaywallOutcome()
        }
    }

}

/// Objective-C-compatible dismissed paywall outcome.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallDismissedOutcome)
public final class ObjCCheckpointPaywallDismissedOutcome: ObjCCheckpointPaywallOutcome {}

/// Objective-C-compatible purchased paywall outcome.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallPurchasedOutcome)
public final class ObjCCheckpointPaywallPurchasedOutcome: ObjCCheckpointPaywallOutcome {

    init(_ value: CheckpointPaywallPurchasedOutcome) {
        self.transaction = value.transaction
        self.customerInfo = value.customerInfo
        super.init()
    }

    /// The transaction completed by the purchase, if available.
    @objc public let transaction: StoreTransaction?

    /// Customer information after the completed purchase.
    @objc public let customerInfo: CustomerInfo

}

/// Objective-C-compatible restored paywall outcome.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallRestoredOutcome)
public final class ObjCCheckpointPaywallRestoredOutcome: ObjCCheckpointPaywallOutcome {

    init(_ value: CheckpointPaywallRestoredOutcome) {
        self.customerInfo = value.customerInfo
        super.init()
    }

    /// Customer information after restoring purchases.
    @objc public let customerInfo: CustomerInfo

}

/// Objective-C-compatible error paywall outcome.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@objc(RCCheckpointPaywallErrorOutcome)
public final class ObjCCheckpointPaywallErrorOutcome: ObjCCheckpointPaywallOutcome {

    init(_ value: CheckpointPaywallErrorOutcome) {
        self.error = value.error
        super.init()
    }

    /// The error that ended the checkpoint experience.
    @objc public let error: PublicError

}

#endif
