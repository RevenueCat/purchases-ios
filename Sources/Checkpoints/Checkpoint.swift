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
//  Created by RevenueCat.
//

import Foundation

/// Per-call parameters for ``Purchases/checkpoint(_:params:)``.
///
/// Custom property values must be a `String`, number, or `Bool`.
@_spi(Internal) public struct CheckpointParams {

    /// Custom properties usable in checkpoint targeting rules.
    public let customProperties: [String: Any]

    /// Creates parameters with optional custom properties.
    public init(customProperties: [String: Any] = [:]) {
        self.customProperties = customProperties.reduce(into: [:]) { validProperties, property in
            let (key, value) = property
            guard Self.isValidCustomPropertyValue(value) else {
                Logger.warn(
                    CheckpointStrings.invalidCustomProperty(
                        key: key,
                        type: String(reflecting: type(of: value))
                    )
                )
                return
            }
            validProperties[key] = value
        }
    }

    private static func isValidCustomPropertyValue(_ value: Any) -> Bool {
        switch value {
        case is String, is Bool,
             is Int, is Int8, is Int16, is Int32, is Int64,
             is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
             is Float, is Double, is Decimal, is NSNumber:
            return true
        default:
            return false
        }
    }

}

/// Information about a checkpoint that was hit.
@_spi(Internal) public struct CheckpointInfo {

    /// The checkpoint identifier configured in the RevenueCat dashboard.
    public let identifier: String

    /// The parameters registered with the checkpoint.
    public let params: CheckpointParams

    init(identifier: String, params: CheckpointParams) {
        self.identifier = identifier
        self.params = params
    }

}

/// The reason no experience was served for a checkpoint.
@_spi(Internal) public struct CheckpointNoActionReason: Equatable, Hashable, Sendable {

    /// The value identifying the reason.
    public let value: String

    /// No targeting rule matched.
    public static let noMatch = Self(value: "NO_MATCH")

    /// The customer was assigned to a holdout.
    public static let holdout = Self(value: "HOLDOUT")

    /// The customer reached the configured frequency cap.
    public static let frequencyCapped = Self(value: "FREQUENCY_CAPPED")

    /// Checkpoint configuration could not be loaded.
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")

    /// Checkpoints are disabled.
    public static let disabled = Self(value: "DISABLED")

    init(value: String) {
        self.value = value
    }

}

/// Base class for the result of hitting a checkpoint.
///
/// Inspect the concrete subclass to determine the outcome. This class cannot be initialized or subclassed outside
/// the SDK, allowing RevenueCat to add new result subclasses without breaking exhaustive switches in applications.
@_spi(Internal) public class CheckpointResult: CustomStringConvertible {

    /// Information about the checkpoint that produced this result.
    public let checkpoint: CheckpointInfo

    fileprivate init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

    /// A debug description of the checkpoint result.
    public var description: String {
        return "CheckpointResult(checkpoint=\(self.checkpoint))"
    }

}

/// A checkpoint-triggered paywall was presented and finished.
@_spi(Internal) public final class CheckpointPaywallPresentedResult: CheckpointResult {

    /// The terminal outcome of the presented paywall.
    public let paywallOutcome: CheckpointPaywallOutcome

    init(checkpoint: CheckpointInfo, paywallOutcome: CheckpointPaywallOutcome) {
        self.paywallOutcome = paywallOutcome
        super.init(checkpoint: checkpoint)
    }

    /// A debug description of the presented-paywall result.
    public override var description: String {
        return "PaywallPresented(checkpoint=\(self.checkpoint), paywallOutcome=\(self.paywallOutcome))"
    }

}

/// Nothing was served for a checkpoint.
@_spi(Internal) public final class CheckpointNoActionResult: CheckpointResult {

    /// The reason no experience was served.
    public let reason: CheckpointNoActionReason

    init(checkpoint: CheckpointInfo, reason: CheckpointNoActionReason) {
        self.reason = reason
        super.init(checkpoint: checkpoint)
    }

    /// A debug description of the no-action result.
    public override var description: String {
        return "NoAction(checkpoint=\(self.checkpoint), reason=\(self.reason))"
    }

}

/// Base class for the terminal result of a checkpoint-presented paywall.
///
/// Inspect the concrete subclass to determine the outcome. This class cannot be initialized or subclassed outside
/// the SDK, allowing RevenueCat to add new result subclasses without breaking exhaustive switches in applications.
@_spi(Internal) public class CheckpointPaywallOutcome: CustomStringConvertible {

    fileprivate init() {}

    /// A debug description of the paywall outcome.
    public var description: String {
        return "CheckpointPaywallOutcome"
    }

}

/// The customer dismissed the paywall.
@_spi(Internal) public final class CheckpointPaywallDismissedOutcome: CheckpointPaywallOutcome {

    /// Creates a dismissed paywall outcome.
    public override init() {
        super.init()
    }

    /// A debug description of the dismissed outcome.
    public override var description: String { return "Dismissed" }

}

/// The customer completed a purchase.
@_spi(Internal) public final class CheckpointPaywallPurchasedOutcome: CheckpointPaywallOutcome {

    /// Customer information after the completed purchase.
    public let customerInfo: CustomerInfo

    /// Creates a purchased outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    /// A debug description of the purchased outcome.
    public override var description: String { return "Purchased" }

}

/// The customer restored purchases.
@_spi(Internal) public final class CheckpointPaywallRestoredOutcome: CheckpointPaywallOutcome {

    /// Customer information after restoring purchases.
    public let customerInfo: CustomerInfo

    /// Creates a restored outcome with the latest customer information.
    public init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        super.init()
    }

    /// A debug description of the restored outcome.
    public override var description: String { return "Restored" }

}

/// The paywall ended with an error.
@_spi(Internal) public final class CheckpointPaywallErrorOutcome: CheckpointPaywallOutcome {

    /// The error that ended the checkpoint experience.
    public let error: PublicError

    /// Creates a paywall error outcome.
    public init(error: PublicError) {
        self.error = error
        super.init()
    }

    /// A debug description of the error outcome.
    public override var description: String {
        return "Error(error=\(self.error))"
    }

}

/// Global listener for checkpoint activity.
///
/// All methods are called on the main thread.
@_spi(Internal) public protocol CheckpointListener: AnyObject {

    /// A checkpoint was hit, before evaluation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo)

    /// The checkpoint was resolved and the outcome was returned.
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointResult)

    /// A checkpoint-presented paywall finished.
    func onCheckpointPaywallFinished(_ checkpoint: CheckpointInfo, outcome: CheckpointPaywallOutcome)

}

@_spi(Internal) public extension CheckpointListener {

    /// Default no-op implementation.
    func onCheckpointHit(_ checkpoint: CheckpointInfo) {}

    /// Default no-op implementation.
    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointResult) {}

    /// Default no-op implementation.
    func onCheckpointPaywallFinished(_ checkpoint: CheckpointInfo, outcome: CheckpointPaywallOutcome) {}

}

// MARK: - Debug descriptions

extension CheckpointParams: CustomStringConvertible {

    /// A debug description of the checkpoint parameters.
    public var description: String {
        return "CheckpointParams(customProperties=\(self.customProperties))"
    }

}

extension CheckpointInfo: CustomStringConvertible {

    /// A debug description of the checkpoint information.
    public var description: String {
        return "CheckpointInfo(identifier='\(self.identifier)', params=\(self.params))"
    }

}

extension CheckpointNoActionReason: CustomStringConvertible {

    /// The raw reason value.
    public var description: String { return self.value }

}
